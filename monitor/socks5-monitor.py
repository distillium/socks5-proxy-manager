#!/usr/bin/env python3

import json
import os
import re
import subprocess
import sys
import time
import argparse
import threading
from http.server import HTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
from urllib.request import urlopen, Request
from urllib.error import URLError

# GeoIP cache — resolves IP → country via ip-api.com, caches permanently
_geoip_cache = {}  # {ip: {"country": "Sweden", "countryCode": "SE"}}
_geoip_lock = threading.Lock()
_geoip_pending = set()


def _resolve_geoip_batch(ips):
    global _geoip_cache
    to_resolve = [ip for ip in ips if ip not in _geoip_cache and ip not in _geoip_pending]
    if not to_resolve:
        return

    with _geoip_lock:
        _geoip_pending.update(to_resolve)

    for i in range(0, len(to_resolve), 100):
        batch = to_resolve[i:i + 100]
        try:
            payload = json.dumps(batch).encode()
            req = Request(
                "http://ip-api.com/batch?fields=query,country,countryCode",
                data=payload,
                headers={"Content-Type": "application/json"},
            )
            resp = urlopen(req, timeout=5)
            results = json.loads(resp.read().decode())
            with _geoip_lock:
                for item in results:
                    ip = item.get("query", "")
                    _geoip_cache[ip] = {
                        "country": item.get("country", "Unknown"),
                        "countryCode": item.get("countryCode", "XX"),
                    }
                    _geoip_pending.discard(ip)
        except Exception:
            with _geoip_lock:
                for ip in batch:
                    _geoip_pending.discard(ip)


def get_geoip(ip):
    return _geoip_cache.get(ip)


def resolve_new_ips(ips):
    unknown = [ip for ip in ips if ip not in _geoip_cache and ip not in _geoip_pending]
    if unknown:
        t = threading.Thread(target=_resolve_geoip_batch, args=(unknown,), daemon=True)
        t.start()

# Metrics collection
PROFILES_FILE = "/etc/socks5-manager/profiles.json"

# For CPU usage delta calculation
_prev_cpu = None
_prev_cpu_time = 0


def _read_file(path):
    try:
        return Path(path).read_text()
    except Exception:
        return ""


def load_profiles():
    try:
        data = json.loads(_read_file(PROFILES_FILE))
        if isinstance(data, list):
            return data
    except Exception:
        pass
    return []


def get_cpu_percent():
    global _prev_cpu, _prev_cpu_time

    try:
        line = _read_file("/proc/stat").split("\n")[0]
        parts = line.split()
        vals = list(map(int, parts[1:]))
        idle = vals[3] + (vals[4] if len(vals) > 4 else 0)
        total = sum(vals)
    except Exception:
        return 0.0

    now = time.monotonic()
    if _prev_cpu is None or (now - _prev_cpu_time) > 30:
        _prev_cpu = (idle, total)
        _prev_cpu_time = now
        if total == 0:
            return 0.0
        return round((1 - idle / total) * 100, 1)

    prev_idle, prev_total = _prev_cpu
    d_idle = idle - prev_idle
    d_total = total - prev_total
    _prev_cpu = (idle, total)
    _prev_cpu_time = now

    if d_total == 0:
        return 0.0
    return round((1 - d_idle / d_total) * 100, 1)


def get_memory():
    info = {}
    for line in _read_file("/proc/meminfo").split("\n"):
        if ":" in line:
            key, val = line.split(":", 1)
            num = re.findall(r"\d+", val)
            if num:
                info[key.strip()] = int(num[0])

    total = info.get("MemTotal", 1)
    available = info.get("MemAvailable", info.get("MemFree", 0))
    used = total - available
    return {
        "total_mb": round(total / 1024, 1),
        "used_mb": round(used / 1024, 1),
        "percent": round(used / total * 100, 1) if total else 0,
    }


def get_disk():
    try:
        st = os.statvfs("/")
        total = st.f_blocks * st.f_frsize
        free = st.f_bavail * st.f_frsize
        used = total - free
        return {
            "total_gb": round(total / (1024**3), 1),
            "used_gb": round(used / (1024**3), 1),
            "percent": round(used / total * 100, 1) if total else 0,
        }
    except Exception:
        return {"total_gb": 0, "used_gb": 0, "percent": 0}


def get_uptime():
    try:
        secs = float(_read_file("/proc/uptime").split()[0])
        days = int(secs // 86400)
        hours = int((secs % 86400) // 3600)
        mins = int((secs % 3600) // 60)
        return f"{days}d {hours}h {mins}m"
    except Exception:
        return "N/A"


def get_load_average():
    try:
        parts = _read_file("/proc/loadavg").split()
        return {"1m": float(parts[0]), "5m": float(parts[1]), "15m": float(parts[2])}
    except Exception:
        return {"1m": 0, "5m": 0, "15m": 0}


def get_connections_per_port(ports):
    result = {p: set() for p in ports}

    # Source 1: ss — all active TCP states
    try:
        out = subprocess.check_output(
            ["ss", "-tn"], text=True, timeout=5
        )
        for line in out.strip().split("\n")[1:]:
            parts = line.split()
            if len(parts) < 5:
                continue
            local_addr = parts[3]
            peer_addr = parts[4]

            lport_match = re.search(r":(\d+)$", local_addr)
            if not lport_match:
                continue
            lport = int(lport_match.group(1))

            if lport in result:
                peer_match = re.match(r"\[?([^\]]+)\]?:(\d+)$", peer_addr)
                if peer_match:
                    result[lport].add((peer_match.group(1), int(peer_match.group(2))))
                else:
                    idx = peer_addr.rfind(":")
                    if idx > 0:
                        result[lport].add((peer_addr[:idx], peer_addr[idx + 1:]))
    except Exception:
        pass

    # Source 2: conntrack (if available) — catches tracked connections
    try:
        for port in ports:
            out = subprocess.check_output(
                ["conntrack", "-L", "-p", "tcp", "--dport", str(port)],
                text=True, stderr=subprocess.DEVNULL, timeout=5
            )
            for line in out.strip().split("\n"):
                if not line.strip():
                    continue
                src_match = re.search(r"src=(\S+)", line)
                sport_match = re.search(r"sport=(\d+)", line)
                if src_match and sport_match:
                    result[port].add((src_match.group(1), int(sport_match.group(1))))
    except FileNotFoundError:
        # conntrack not installed — that's fine, ss is the fallback
        pass
    except Exception:
        pass

    # Convert sets to list of dicts
    final = {}
    for port, peers in result.items():
        final[port] = [{"remote_ip": ip, "remote_port": rp} for ip, rp in peers]
    return final


def get_iptables_packet_counts(ports):
    result = {p: 0 for p in ports}
    try:
        out = subprocess.check_output(
            ["iptables", "-L", "INPUT", "-v", "-n", "-x"], text=True, timeout=5
        )
        for line in out.strip().split("\n"):
            line = line.strip()
            if not line or line.startswith("Chain") or line.startswith("pkts"):
                continue
            parts = line.split()
            if len(parts) < 10:
                continue
            try:
                pkts = int(parts[0])
            except ValueError:
                continue
            dpt_match = re.search(r"dpt:(\d+)", line)
            if dpt_match:
                port = int(dpt_match.group(1))
                if port in result:
                    result[port] = pkts
    except Exception:
        pass
    return result


def ensure_iptables_rules(ports):
    for port in ports:
        for chain, flag in [("INPUT", "--dport"), ("OUTPUT", "--sport")]:
            # Check if rule already exists
            check = subprocess.run(
                ["iptables", "-C", chain, "-p", "tcp", flag, str(port)],
                capture_output=True,
            )
            if check.returncode != 0:
                subprocess.run(
                    ["iptables", "-A", chain, "-p", "tcp", flag, str(port)],
                    capture_output=True,
                )


def get_traffic_per_port(ports):
    result = {p: {"rx_bytes": 0, "tx_bytes": 0} for p in ports}
    try:
        for chain, direction in [("INPUT", "rx_bytes"), ("OUTPUT", "tx_bytes")]:
            out = subprocess.check_output(
                ["iptables", "-L", chain, "-v", "-n", "-x"], text=True, timeout=5
            )
            for line in out.strip().split("\n"):
                line = line.strip()
                if not line or line.startswith("Chain") or line.startswith("pkts"):
                    continue
                parts = line.split()
                if len(parts) < 10:
                    continue
                try:
                    bytes_val = int(parts[1])
                except ValueError:
                    continue
                # Match dpt:PORT or spt:PORT
                dpt_match = re.search(r"[ds]pt:(\d+)", line)
                if dpt_match:
                    port = int(dpt_match.group(1))
                    if port in result:
                        result[port][direction] = bytes_val
    except Exception:
        pass
    return result


def get_dante_status():
    try:
        r = subprocess.run(
            ["systemctl", "is-active", "danted"], capture_output=True, text=True, timeout=5
        )
        return r.stdout.strip() == "active"
    except Exception:
        return False


def collect_all():
    profiles = load_profiles()
    ports = [p["port"] for p in profiles if "port" in p]

    # Ensure iptables accounting rules exist
    if ports:
        try:
            ensure_iptables_rules(ports)
        except Exception:
            pass

    connections = get_connections_per_port(ports)
    traffic = get_traffic_per_port(ports)
    packets = get_iptables_packet_counts(ports)

    # Collect all unique IPs and trigger GeoIP resolution
    all_ips = set()
    for port_conns in connections.values():
        for c in port_conns:
            all_ips.add(c["remote_ip"])
    if all_ips:
        resolve_new_ips(list(all_ips))

    profiles_out = []
    for p in profiles:
        port = p.get("port")
        conns = connections.get(port, [])
        traf = traffic.get(port, {"rx_bytes": 0, "tx_bytes": 0})
        pkts = packets.get(port, 0)

        # Enrich clients with GeoIP — deduplicate by IP
        seen_ips = set()
        enriched_clients = []
        for c in conns:
            ip = c["remote_ip"]
            if ip in seen_ips:
                continue
            seen_ips.add(ip)
            geo = get_geoip(ip)
            enriched_clients.append({
                "remote_ip": ip,
                "country": geo["country"] if geo else "Resolving...",
                "countryCode": geo["countryCode"] if geo else "XX",
            })

        profiles_out.append({
            "name": p.get("name", "unknown"),
            "port": port,
            "username": p.get("username", ""),
            "created": p.get("created", ""),
            "connections": len(enriched_clients),
            "total_packets": pkts,
            "clients": enriched_clients,
            "rx_bytes": traf["rx_bytes"],
            "tx_bytes": traf["tx_bytes"],
        })

    return {
        "timestamp": int(time.time()),
        "server": {
            "cpu_percent": get_cpu_percent(),
            "memory": get_memory(),
            "disk": get_disk(),
            "load": get_load_average(),
            "uptime": get_uptime(),
            "dante_active": get_dante_status(),
        },
        "profiles": profiles_out,
        "total_connections": sum(pr["connections"] for pr in profiles_out),
    }


# HTTP server with Basic Auth
# Global auth credentials (set from CLI args)
_auth_user = None
_auth_pass = None


def _check_auth(handler):
    if not _auth_user:
        return True  # No auth configured

    auth_header = handler.headers.get("Authorization", "")
    if not auth_header.startswith("Basic "):
        return False

    import base64
    try:
        decoded = base64.b64decode(auth_header[6:]).decode()
        user, password = decoded.split(":", 1)
        return user == _auth_user and password == _auth_pass
    except Exception:
        return False


def _send_auth_required(handler):
    handler.send_response(401)
    handler.send_header("WWW-Authenticate", 'Basic realm="SOCKS5 Monitor"')
    handler.send_header("Content-Type", "text/html")
    handler.end_headers()
    handler.wfile.write(b"<h1>401 Unauthorized</h1>")


class MonitorHandler(SimpleHTTPRequestHandler):

    def do_GET(self):
        if not _check_auth(self):
            _send_auth_required(self)
            return

        if self.path == "/api/stats":
            try:
                data = collect_all()
                payload = json.dumps(data, ensure_ascii=False).encode()
                self.send_response(200)
                self.send_header("Content-Type", "application/json; charset=utf-8")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.send_header("Cache-Control", "no-cache")
                self.send_header("Content-Length", str(len(payload)))
                self.end_headers()
                self.wfile.write(payload)
            except Exception as exc:
                err = json.dumps({"error": str(exc)}).encode()
                self.send_response(500)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(err)))
                self.end_headers()
                self.wfile.write(err)
        else:
            super().do_GET()

    def log_message(self, format, *args):
        pass


def run_server(host, port, directory):
    os.chdir(directory)
    server = HTTPServer((host, port), MonitorHandler)
    auth_info = f" (auth: {_auth_user})" if _auth_user else " (no auth)"
    print(f"[socks5-monitor] Dashboard: http://{host}:{port}{auth_info}")
    print(f"[socks5-monitor] Serving from {directory}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[socks5-monitor] Shutting down.")
        server.shutdown()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="SOCKS5 Proxy Monitor")
    parser.add_argument("--host", default="0.0.0.0", help="Bind address (default: 0.0.0.0)")
    parser.add_argument("--port", type=int, default=9090, help="HTTP port (default: 9090)")
    parser.add_argument("--dir", default="/var/www/socks5-monitor", help="Web root directory")
    parser.add_argument("--user", default=None, help="Basic auth username (optional)")
    parser.add_argument("--password", default=None, help="Basic auth password (optional)")
    args = parser.parse_args()

    if args.user and args.password:
        _auth_user = args.user
        _auth_pass = args.password
    elif args.user or args.password:
        print("[socks5-monitor] WARNING: Both --user and --password required for auth. Running without auth.")

    run_server(args.host, args.port, args.dir)
