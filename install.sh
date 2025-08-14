#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE="$CYAN"
NC='\033[0m'

MANAGER_DIR="/etc/socks5-manager"
PROFILES_FILE="$MANAGER_DIR/profiles.json"
SCRIPT_PATH="/usr/local/bin/socks"
DANTE_CONFIG="/etc/danted.conf"

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

init_manager() {
    if [ ! -d "$MANAGER_DIR" ]; then
        mkdir -p "$MANAGER_DIR"
        echo "[]" > "$PROFILES_FILE"
    fi

    setup_socks_command
}

setup_socks_command() {
    local target="/usr/local/bin/socks5-manager.sh"
    local link_path="/usr/local/bin/socks"

    local source_script
    if [ -n "${BASH_SOURCE[0]}" ]; then
        source_script="$(readlink -f "${BASH_SOURCE[0]}")"
    else
        source_script="$(readlink -f "$0")"
    fi

    if [ ! -f "$target" ]; then
        cp "$source_script" "$target"
        chmod +x "$target"
        print_status "Скрипт скопирован в постоянное место: $target"
    fi

    if [ -L "$link_path" ] || [ -f "$link_path" ]; then
        rm -f "$link_path"
    fi
    ln -s "$target" "$link_path"
    chmod +x "$link_path"

    if [ ! -x "$link_path" ]; then
        print_warning "Не удалось создать команду 'socks'"
    fi
}

install_dependencies() {
    print_status "Обновление пакетов и установка зависимостей..."
    apt update > /dev/null 2>&1 && apt install -y dante-server jq > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        print_error "Ошибка при установке пакетов"
        exit 1
    fi
}

generate_random_port() {
    while :; do
        port=$((RANDOM % 64512 + 1024))
        if ! ss -tulnp | awk '{print $4}' | grep -q ":$port" && ! is_port_used_by_profiles "$port"; then
            echo $port
            return
        fi
    done
}

is_port_used_by_profiles() {
    local check_port=$1
    if [ -f "$PROFILES_FILE" ]; then
        jq -r '.[].port' "$PROFILES_FILE" 2>/dev/null | grep -q "^$check_port$"
    else
        return 1
    fi
}

get_next_profile_number() {
    if [ ! -f "$PROFILES_FILE" ]; then
        echo 1
        return
    fi
    
    local max_num=0
    while IFS= read -r name; do
        if [[ "$name" =~ ^socks5-([0-9]+)$ ]]; then
            local num=${BASH_REMATCH[1]}
            if [ "$num" -gt "$max_num" ]; then
                max_num=$num
            fi
        fi
    done < <(jq -r '.[].name' "$PROFILES_FILE" 2>/dev/null)
    
    echo $((max_num + 1))
}

generate_dante_config() {
    local INTERFACE=$(ip route get 8.8.8.8 | awk -- '{print $5}' | head -n 1)
    
    cat > "$DANTE_CONFIG" <<EOL
logoutput: /var/log/danted.log
user.privileged: root
user.notprivileged: nobody

EOL

    if [ -f "$PROFILES_FILE" ] && [ "$(jq length "$PROFILES_FILE")" -gt 0 ]; then
        while IFS= read -r profile; do
            local port=$(echo "$profile" | jq -r '.port')
            echo "internal: 0.0.0.0 port = $port" >> "$DANTE_CONFIG"
        done < <(jq -c '.[]' "$PROFILES_FILE")
    fi
    
    cat >> "$DANTE_CONFIG" <<EOL

external: $INTERFACE
socksmethod: username

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    method: username
    protocol: tcp udp
    log: error
}
EOL
}

create_profile() {
    print_header "СОЗДАНИЕ НОВОГО SOCKS5 ПРОФИЛЯ"
    
    echo ""
    read -p "Введите название профиля (Enter для автогенерации): " profile_name
    
    if [ -z "$profile_name" ]; then
        local next_num=$(get_next_profile_number)
        profile_name="socks5-$next_num"
        print_status "Создается профиль: $profile_name"
    fi
    
    if profile_exists "$profile_name"; then
        print_error "Профиль '$profile_name' уже существует!"
        return 1
    fi
    
    INTERFACE=$(ip route get 8.8.8.8 | awk -- '{print $5}' | head -n 1)
    print_status "Обнаружен сетевой интерфейс: $INTERFACE"
    
    echo ""
    print_header "НАСТРОЙКА АУТЕНТИФИКАЦИИ"
    read -p "Ввести логин и пароль вручную? [y/N]: " choice
    
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        read -p "Имя пользователя: " username
        read -s -p "Пароль: " password
        echo ""
    else
        username=$(tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 8)
        password=$(tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 12)
        print_status "Сгенерированы учетные данные:"
        echo "  Логин: $username"
        echo "  Пароль: $password"
    fi
    
    echo ""
    print_header "НАСТРОЙКА ПОРТА"
    read -p "Указать порт вручную? [y/N]: " port_choice
    
    if [[ "$port_choice" =~ ^[Yy]$ ]]; then
        while :; do
            read -p "Введите порт (1024-65535): " port
            if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1024 ] && [ "$port" -le 65535 ] && ! ss -tulnp | awk '{print $4}' | grep -q ":$port" && ! is_port_used_by_profiles "$port"; then
                break
            else
                print_warning "Порт недоступен или некорректный. Попробуйте снова."
            fi
        done
    else
        port=$(generate_random_port)
        print_status "Назначен порт: $port"
    fi
    
    print_status "Создание системного пользователя..."
    useradd -r -s /bin/false "$username" 2>/dev/null
    (echo "$password"; echo "$password") | passwd "$username" > /dev/null 2>&1
    
    save_profile "$profile_name" "$port" "$username" "$password"
    
    print_status "Обновление конфигурации Dante..."
    generate_dante_config
    
    print_status "Настройка брандмауэра..."
    ufw allow "$port/tcp" > /dev/null 2>&1
    
    print_status "Перезапуск службы..."
    systemctl restart danted
    systemctl enable danted > /dev/null 2>&1
    
    if ! systemctl is-active --quiet danted; then
        print_error "Не удалось запустить службу Dante"
        return 1
    fi
    
    local external_ip=$(curl -4 -s ifconfig.me)
    
    echo ""
    print_header "ПРОФИЛЬ СОЗДАН УСПЕШНО"
    print_success "SOCKS5 прокси-сервер '$profile_name' настроен!"
    echo ""
    echo -e "${BLUE}Параметры подключения:${NC}"
    echo "  Название: $profile_name"
    echo "  IP адрес: $external_ip"
    echo "  Порт: $port"
    echo "  Логин: $username"
    echo "  Пароль: $password"
    echo ""
    echo -e "${BLUE}Форматы для антидетект браузеров:${NC}"
    echo "  $external_ip:$port:$username:$password"
    echo "  $username:$password@$external_ip:$port"
    echo ""
}

save_profile() {
    local name=$1
    local port=$2
    local username=$3
    local password=$4
    
    local new_profile=$(jq -n \
        --arg name "$name" \
        --arg port "$port" \
        --arg username "$username" \
        --arg password "$password" \
        --arg created "$(date -Iseconds)" \
        '{
            name: $name,
            port: ($port | tonumber),
            username: $username,
            password: $password,
            created: $created
        }')
    
    jq ". + [$new_profile]" "$PROFILES_FILE" > "$PROFILES_FILE.tmp" && mv "$PROFILES_FILE.tmp" "$PROFILES_FILE"
}

profile_exists() {
    local name=$1
    if [ -f "$PROFILES_FILE" ]; then
        jq -e ".[] | select(.name == \"$name\")" "$PROFILES_FILE" > /dev/null 2>&1
    else
        return 1
    fi
}

show_connections() {
    print_header "АКТИВНЫЕ SOCKS5 ПОДКЛЮЧЕНИЯ"
    
    if [ ! -f "$PROFILES_FILE" ] || [ "$(jq length "$PROFILES_FILE")" -eq 0 ]; then
        print_warning "Нет созданных профилей"
        return
    fi
    
    local external_ip=$(curl -4 -s ifconfig.me 2>/dev/null || echo "N/A")
    local service_status=""
    if systemctl is-active --quiet danted; then
        service_status="${GREEN}АКТИВЕН${NC}"
    else
        service_status="${RED}ОСТАНОВЛЕН${NC}"
    fi

    echo ""
    echo -e "${CYAN}Список профилей:${NC}"
    echo ""
    
    local counter=1
    declare -a profile_names=()
    
    while IFS= read -r profile; do
        local name=$(echo "$profile" | jq -r '.name')
        local port=$(echo "$profile" | jq -r '.port')
        profile_names+=("$name")
        echo -e "${CYAN}$counter.${NC} $name (порт: $port)"
        ((counter++))
    done < <(jq -c '.[]' "$PROFILES_FILE")
    
    echo ""
    echo -e "${CYAN}0.${NC} Назад в главное меню"
    echo ""
    read -p "Выберите профиль для просмотра (0-$((counter-1))): " selection
    
    if [[ "$selection" == "0" ]]; then
        return
    fi
    
    if ! [[ "$selection" =~ ^[1-9][0-9]*$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -ge $counter ]; then
        print_error "Неверный выбор"
        sleep 1
        return
    fi
    
    local selected_profile=$(echo "${profile_names[$((selection-1))]}")
    local profile_data=$(jq ".[] | select(.name == \"$selected_profile\")" "$PROFILES_FILE")
    
    local name=$(echo "$profile_data" | jq -r '.name')
    local port=$(echo "$profile_data" | jq -r '.port')
    local username=$(echo "$profile_data" | jq -r '.username')
    local password=$(echo "$profile_data" | jq -r '.password')
    local created=$(echo "$profile_data" | jq -r '.created')
    
    clear
    print_header "ИНФОРМАЦИЯ О ПРОФИЛЕ: $name"
    echo ""
    echo -e "${BLUE}Параметры подключения:${NC}"
    echo "  Название: $name"
    echo "  IP адрес: $external_ip"
    echo "  Порт: $port"
    echo "  Логин: $username"
    echo "  Пароль: $password"
    echo -e "  Статус: $service_status"
    echo "  Создан: $created"
    echo ""
    echo -e "${BLUE}Форматы для антидетект браузеров:${NC}"
    echo "  $external_ip:$port:$username:$password"
    echo "  $username:$password@$external_ip:$port"
    echo ""
    
    read -p "Нажмите Enter для возврата к списку..."
    clear
    show_connections
}

delete_profile() {
    print_header "УДАЛЕНИЕ SOCKS5 ПРОФИЛЯ"
    
    if [ ! -f "$PROFILES_FILE" ] || [ "$(jq length "$PROFILES_FILE")" -eq 0 ]; then
        print_warning "Нет профилей для удаления"
        return
    fi
    
    echo ""
    echo "Доступные профили:"
    jq -r '.[] | "  - \(.name) (порт: \(.port))"' "$PROFILES_FILE"
    echo ""
    
    read -p "Введите название профиля для удаления: " profile_name
    
    if [ -z "$profile_name" ]; then
        print_warning "Название профиля не указано"
        return
    fi
    
    if ! profile_exists "$profile_name"; then
        print_error "Профиль '$profile_name' не найден"
        return
    fi
    
    local profile_data=$(jq ".[] | select(.name == \"$profile_name\")" "$PROFILES_FILE")
    local username=$(echo "$profile_data" | jq -r '.username')
    local port=$(echo "$profile_data" | jq -r '.port')
    
    echo ""
    read -p "Вы уверены, что хотите удалить профиль '$profile_name'? [y/N]: " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_warning "Удаление отменено"
        return
    fi
    
    print_status "Удаление профиля '$profile_name'..."
    
    userdel "$username" 2>/dev/null
    
    ufw delete allow "$port/tcp" > /dev/null 2>&1
    
    jq "del(.[] | select(.name == \"$profile_name\"))" "$PROFILES_FILE" > "$PROFILES_FILE.tmp" && mv "$PROFILES_FILE.tmp" "$PROFILES_FILE"
    
    print_status "Обновление конфигурации Dante..."
    generate_dante_config
    
    if [ "$(jq length "$PROFILES_FILE")" -gt 0 ]; then
        systemctl restart danted
    else
        print_warning "Это был последний профиль. Остановка службы Dante."
        systemctl stop danted
    fi
    
    print_success "Профиль '$profile_name' успешно удален"
}

uninstall_manager() {
    print_header "ПОЛНОЕ УДАЛЕНИЕ SOCKS5 МЕНЕДЖЕРА"
    
    echo ""
    echo -e "${RED}ВНИМАНИЕ: Это действие удалит ВСЕ профили и конфигурации!${NC}"
    echo ""
    read -p "Вы уверены? Введите 'YES' для подтверждения: " confirm
    
    if [ "$confirm" != "YES" ]; then
        print_warning "Удаление отменено"
        return
    fi
    
    print_status "Удаление всех профилей и конфигураций..."
    
    systemctl stop danted 2>/dev/null
    systemctl disable danted 2>/dev/null
    
    if [ -f "$PROFILES_FILE" ]; then
        while IFS= read -r profile; do
            local username=$(echo "$profile" | jq -r '.username')
            local port=$(echo "$profile" | jq -r '.port')
            userdel "$username" 2>/dev/null
            ufw delete allow "$port/tcp" > /dev/null 2>&1
        done < <(jq -c '.[]' "$PROFILES_FILE")
    fi
    
    rm -rf "$MANAGER_DIR"
    rm -f "$DANTE_CONFIG"
    rm -f "$SCRIPT_PATH"
    rm -f /usr/local/bin/socks5-manager.sh
    DEBIAN_FRONTEND=noninteractive apt --purge remove -y dante-server > /dev/null 2>&1
    
    print_success "SOCKS5 менеджер полностью удален"
}

show_main_menu() {
    while true; do
        clear
        print_header "SOCKS5 PROXY MANAGER by distillium"
        echo ""
        echo -e "${CYAN}1.${NC} Показать все подключения"
        echo -e "${CYAN}2.${NC} Создать новое подключение"
        echo ""
        echo -e "${CYAN}3.${NC} Удалить подключение"
        echo -e "${CYAN}4.${NC} Удалить менеджер и все конфигурации"
        echo ""
        echo -e "${CYAN}0.${NC} Выход"
        echo ""
        read -p "Выберите пункт меню (0-4): " choice
        echo -e "–  Быстрый запуск: ${CYAN}socks${NC} доступен из любой точки системы"
        case $choice in
            1)
                clear
                show_connections
                echo ""
                read -p "Нажмите Enter для продолжения..."
                ;;
            2)
                clear
                create_profile
                echo ""
                read -p "Нажмите Enter для продолжения..."
                ;;
            3)
                clear
                delete_profile
                echo ""
                read -p "Нажмите Enter для продолжения..."
                ;;
            4)
                clear
                uninstall_manager
                exit 0
                ;;
            0)
                echo ""
                print_status "До свидания!"
                exit 0
                ;;
            *)
                print_error "Неверный выбор. Попробуйте снова."
                sleep 1
                ;;
        esac
    done
}

main() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Этот скрипт должен быть запущен с правами root"
        exit 1
    fi

    if [ ! -d "$MANAGER_DIR" ]; then
        print_status "Установка SOCKS5 MANAGER"
        install_dependencies
        init_manager
        generate_dante_config

        setup_socks_command
        rm -f /root/install.sh
        echo ""
        print_success "Менеджер SOCKS5 прокси успешно установлен!"
        echo ""

        read -p "Создать первый профиль сейчас? [Y/n]: " create_first
        if [[ ! "$create_first" =~ ^[Nn]$ ]]; then
            clear
            create_profile
            echo ""
            read -p "Нажмите Enter для продолжения..."
        fi
    else
        setup_socks_command
    fi

    show_main_menu
}

if [ "$1" = "menu" ] || [ "$1" = "" ]; then
    main
elif [ "$1" = "list" ]; then
    show_connections
elif [ "$1" = "create" ]; then
    if [[ $EUID -ne 0 ]]; then
        print_error "Этот скрипт должен быть запущен с правами root"
        exit 1
    fi
    init_manager
    create_profile
elif [ "$1" = "delete" ]; then
    if [[ $EUID -ne 0 ]]; then
        print_error "Этот скрипт должен быть запущен с правами root"
        exit 1
    fi
    init_manager
    delete_profile
else
    echo "Использование: socks [menu|list|create|delete]"
    echo "  list   - показать все подключения"
    echo "  create - создать новое подключение"
    echo "  delete - удалить подключение"
fi
