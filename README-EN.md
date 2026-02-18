<p align="center"><a href="https://github.com/distillium/socks5-proxy-manager">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="./media/logo.png" />
   <source media="(prefers-color-scheme: light)" srcset="./media/logo-black.png" />
   <img alt="socks5" src="./media/logo.png" />
 </picture>
</a></p>

<p align="center">
  <a href="/README.md">🇷🇺Russian</a> | <a href="/README-EN.md">🇺🇸English</a>
</p>

A script for installing and managing a SOCKS5 proxy based on **Dante** with multi-profile support.

⚠️ Only **Debian/Ubuntu**-based systems are supported.  
ℹ️ **UFW (Uncomplicated Firewall)** must be installed.

## Features:
- One-step installation and configuration of `dante-server`
- Create an unlimited number of SOCKS5 profiles (port, login, password)
- Auto-generation or manual input of credentials and port
- View the list of active connections
- Delete individual profiles or fully uninstall the manager
- Quick launch via the `socks` command from anywhere in the system

---

## Installation:
```bash
wget -q -O install.sh https://raw.githubusercontent.com/distillium/socks5-proxy-manager/main/install.sh && chmod +x install.sh && sudo ./install.sh
```

## Profile Templates:
Standard Display:
```
IP: xxx.xxx.xxx.xxx
Port: 12345
Username: username
Password: password
```

Ready-made output for anti-detection browsers:
```
xxx.xxx.xxx.xxx:12345:username:password
username:password@xxx.xxx.xxx.xxx:12345
```

## Команды:
`socks menu` - open socks menu  
`socks list` - list connection  
`socks create` - create new connection  
`socks delete` - delete connection

## Author:
Created by [distillium](https://github.com/distillium)
