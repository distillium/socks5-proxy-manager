#!/bin/bash

# Version / Версия
SCRIPT_VERSION="2.0.0"

# Colors / Цвета
COLOR_RESET="\033[0m"
COLOR_GREEN="\033[1;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_WHITE="\033[1;37m"
COLOR_RED="\033[1;31m"
COLOR_GRAY='\033[0;90m'
COLOR_BLUE="\033[1;34m"

# Paths / Пути
MANAGER_DIR="/etc/socks5-manager"          # Main manager directory / Основная директория менеджера
PROFILES_FILE="$MANAGER_DIR/profiles.json" # Profiles storage / Хранилище профилей
SCRIPT_PATH="/usr/local/bin/socks"         # Symlink path / Путь симлинка
SCRIPT_TARGET="/usr/local/bin/socks5-manager.sh" # Permanent script location / Постоянное место скрипта
DANTE_CONFIG="/etc/danted.conf"            # Dante config file / Конфиг Dante
LANG_FILE="$MANAGER_DIR/language"          # Saved language choice / Сохранённый выбор языка


# ─────────────────────────────────────────────
#        LANGUAGE SYSTEM / СИСТЕМА ЯЗЫКОВ
# ─────────────────────────────────────────────

declare -A LANG

set_language() {
    case $1 in
        en)
            LANG=(
                # Alias messages / Сообщения псевдонимов
                [ALIAS_ADDED]="Alias 'socks' added to %s"
                [ALIAS_ACTIVATE_GLOBAL]="Alias 'socks' is now available for all users. Run 'source %s' or open a new terminal to apply."

                # Language selector / Выбор языка
                [CHOOSE_LANG]="Select language:"
                [LANG_EN]="English"
                [LANG_RU]="Русский"

                # Root / OS checks / Проверки root и ОС
                [ERROR_ROOT]="This script must be run as root"
                [ERROR_OS]="Supported only Debian 11/12 and Ubuntu 22.04/24.04"

                # Package installation errors / Ошибки установки пакетов
                [ERROR_UPDATE_LIST]="Failed to update package list"
                [ERROR_INSTALL_PACKAGES]="Failed to install required packages"
                [ERROR_INSTALL_CRON]="Failed to install cron"
                [ERROR_START_CRON]="Failed to start cron"
                [ERROR_CONFIGURE_LOCALES]="Failed to configure locales"
                [ERROR_DOWNLOAD_DOCKER_KEY]="Failed to download Docker GPG key"
                [ERROR_UPDATE_DOCKER_LIST]="Failed to update package list after adding Docker repository"
                [ERROR_INSTALL_DOCKER]="Failed to install Docker"
                [ERROR_DOCKER_NOT_INSTALLED]="Docker is not installed"
                [ERROR_START_DOCKER]="Failed to start Docker"
                [ERROR_ENABLE_DOCKER]="Failed to enable Docker auto-start"
                [ERROR_DOCKER_NOT_WORKING]="Docker is not working properly"
                [ERROR_CONFIGURE_UFW]="Failed to configure UFW"
                [ERROR_CONFIGURE_UPGRADES]="Failed to configure unattended-upgrades"
                [ERROR_DOCKER_DNS]="Unable to resolve download.docker.com. Check your DNS settings."
                [ERROR_INSTALL_CERTBOT]="Failed to install certbot"
                [SUCCESS_INSTALL]="All packages installed successfully"

                # First-run setup / Первоначальная установка
                [SETUP_COPYING_SCRIPT]="Script copied to permanent location: %s"
                [SETUP_CMD_WARN]="Failed to create 'socks' command"
                [SETUP_INSTALLING]="Installing SOCKS5 MANAGER"
                [SETUP_DONE]="SOCKS5 proxy manager installed successfully!"
                [SETUP_CREATE_FIRST]="Create first profile now? [Y/n]: "

                # Dependency installation / Установка зависимостей
                [DEPS_UPDATING]="Updating packages and installing dependencies..."
                [DEPS_ERROR]="Failed to install packages"

                # Reinstall / Переустановка
                [REINSTALL_TITLE]="REINSTALL SOCKS5 MANAGER"
                [REINSTALL_WARNING]="WARNING: All profiles and configurations will be DELETED!"
                [REINSTALL_CONFIRM]="Are you sure? Type 'YES' to confirm: "
                [REINSTALL_CANCELLED]="Reinstall cancelled"
                [REINSTALL_REMOVING]="Removing old installation..."
                [REINSTALL_DONE]="Reinstall completed successfully!"

                # Main menu / Главное меню
                [MENU_TITLE]="SOCKS5 PROXY MANAGER by distillium"
                [MENU_SHOW]="Show all profile"
                [MENU_CREATE]="Create new profile"
                [MENU_DELETE]="Delete profile"
                [MENU_UNINSTALL]="Uninstall manager and all configurations"
                [MENU_EXIT]="Exit"
                [MENU_PROMPT]="Select menu item (0-4): "
                [MENU_QUICKSTART]="Quick start: 'socks' available from anywhere in the system"
                [MENU_INVALID]="Invalid choice. Please try again."
                [MENU_GOODBYE]="Goodbye!"

                # Profile creation / Создание профиля
                [CREATE_TITLE]="CREATE NEW SOCKS5 PROFILE"
                [CREATE_NAME_PROMPT]="Enter profile name (Enter for auto-generate): "
                [CREATE_GENERATING]="Creating profile: %s"
                [CREATE_PROFILE_EXISTS]="Profile '%s' already exists!"
                [CREATE_IFACE_DETECTED]="Detected network interface: %s"
                [CREATE_AUTH_TITLE]="AUTHENTICATION SETUP"
                [CREATE_AUTH_MANUAL]="Enter username and password manually? [y/N]: "
                [CREATE_USERNAME_PROMPT]="Username: "
                [CREATE_PASSWORD_PROMPT]="Password: "
                [CREATE_CREDS_GENERATED]="Generated credentials:"
                [CREATE_CREDS_LOGIN]="  Username:    %s"
                [CREATE_CREDS_PASS]="  Password: %s"
                [CREATE_PORT_TITLE]="PORT SETUP"
                [CREATE_PORT_MANUAL]="Specify port manually? [y/N]: "
                [CREATE_PORT_PROMPT]="Enter port (1024-65535): "
                [CREATE_PORT_INVALID]="Port is unavailable or invalid. Please try again."
                [CREATE_PORT_ASSIGNED]="Assigned port: %s"
                [CREATE_SYS_USER]="Creating system user..."
                [CREATE_UPDATE_DANTE]="Updating Dante configuration..."
                [CREATE_SETUP_FW]="Configuring firewall..."
                [CREATE_RESTARTING]="Restarting service..."
                [CREATE_DANTE_FAIL]="Failed to start Dante service. Check: journalctl -u danted"
                [CREATE_SUCCESS_TITLE]="PROFILE CREATED SUCCESSFULLY"
                [CREATE_SUCCESS_MSG]="SOCKS5 proxy server '%s' is configured!"
                [CREATE_CONN_TITLE]="Connection parameters:"
                [CREATE_CONN_NAME]="  Name:     %s"
                [CREATE_CONN_IP]="  IP:       %s"
                [CREATE_CONN_PORT]="  Port:     %s"
                [CREATE_CONN_LOGIN]="  Username:    %s"
                [CREATE_CONN_PASS]="  Password: %s"
                [CREATE_ANTIDETECT_TITLE]="Formats for anti-detect browsers:"

                # Profile list / Список профилей
                [SHOW_TITLE]="ACTIVE SOCKS5 profile"
                [SHOW_NO_PROFILES]="No profiles created"
                [SHOW_LIST_TITLE]="Profile list:"
                [SHOW_PROFILE_ITEM]="%d. %s (port: %s)"
                [SHOW_BACK]="Back to main menu"
                [SHOW_SELECT_PROMPT]="Select profile to view (0-%d): "
                [SHOW_INVALID]="Invalid selection"
                [SHOW_INFO_TITLE]="PROFILE INFO: %s"
                [SHOW_CONN_TITLE]="Profile parameters:"
                [SHOW_STATUS_ACTIVE]="ACTIVE"
                [SHOW_STATUS_STOPPED]="STOPPED"
                [SHOW_CONN_STATUS]="  Status:   %s"
                [SHOW_CONN_CREATED]="  Created:  %s"
                [SHOW_ANTIDETECT_TITLE]="Formats for anti-detect browsers:"
                [SHOW_BACK_PROMPT]="Press Enter to return to list..."

                # Profile deletion / Удаление профиля
                [DELETE_TITLE]="DELETE SOCKS5 PROFILE"
                [DELETE_NO_PROFILES]="No profiles to delete"
                [DELETE_AVAILABLE]="Available profiles:"
                [DELETE_NAME_PROMPT]="Enter profile name to delete: "
                [DELETE_NAME_EMPTY]="Profile name not specified"
                [DELETE_NOT_FOUND]="Profile '%s' not found"
                [DELETE_CONFIRM]="Are you sure you want to delete profile '%s'? [y/N]: "
                [DELETE_CANCELLED]="Deletion cancelled"
                [DELETE_DELETING]="Deleting profile '%s'..."
                [DELETE_UPDATE_DANTE]="Updating Dante configuration..."
                [DELETE_LAST_PROFILE]="This was the last profile. Stopping Dante service."
                [DELETE_SUCCESS]="Profile '%s' deleted successfully"

                # Full uninstall / Полное удаление
                [UNINSTALL_TITLE]="FULL REMOVAL OF SOCKS5 MANAGER"
                [UNINSTALL_WARNING]="WARNING: This will remove ALL profiles, configurations and the script itself!"
                [UNINSTALL_CONFIRM]="Are you sure? Type 'YES' to confirm: "
                [UNINSTALL_CANCELLED]="Removal cancelled"
                [UNINSTALL_REMOVING]="Removing all profiles, configurations and script files..."
                [UNINSTALL_SUCCESS]="SOCKS5 manager fully removed from the system"

                # Common / Общие
                [PRESS_ENTER]="Press Enter to continue..."
                [USAGE]="Usage: socks [menu|list|create|delete|reinstall|uninstall]"
                [USAGE_LIST]="  list      - show all connections"
                [USAGE_CREATE]="  create    - create new connection"
                [USAGE_DELETE]="  delete    - delete connection"
                [USAGE_REINSTALL]="  reinstall - reinstall manager (all data will be lost)"
                [USAGE_UNINSTALL]="  uninstall - fully remove manager from system"
            )
            ;;
        ru)
            LANG=(
                # Alias messages / Сообщения псевдонимов
                [ALIAS_ADDED]="Псевдоним 'socks' добавлен в %s"
                [ALIAS_ACTIVATE_GLOBAL]="Псевдоним 'socks' доступен всем пользователям. Выполните 'source %s' или откройте новый терминал."

                # Language selector / Выбор языка
                [CHOOSE_LANG]="Выберите язык:"
                [LANG_EN]="English"
                [LANG_RU]="Русский"

                # Root / OS checks / Проверки root и ОС
                [ERROR_ROOT]="Этот скрипт должен быть запущен с правами root"
                [ERROR_OS]="Поддерживается только Debian 11/12 и Ubuntu 22.04/24.04"

                # Package installation errors / Ошибки установки пакетов
                [ERROR_UPDATE_LIST]="Не удалось обновить список пакетов"
                [ERROR_INSTALL_PACKAGES]="Не удалось установить необходимые пакеты"
                [ERROR_INSTALL_CRON]="Не удалось установить cron"
                [ERROR_START_CRON]="Не удалось запустить cron"
                [ERROR_CONFIGURE_LOCALES]="Не удалось настроить локали"
                [ERROR_DOWNLOAD_DOCKER_KEY]="Не удалось загрузить GPG-ключ Docker"
                [ERROR_UPDATE_DOCKER_LIST]="Не удалось обновить список пакетов после добавления репозитория Docker"
                [ERROR_INSTALL_DOCKER]="Не удалось установить Docker"
                [ERROR_DOCKER_NOT_INSTALLED]="Docker не установлен"
                [ERROR_START_DOCKER]="Не удалось запустить Docker"
                [ERROR_ENABLE_DOCKER]="Не удалось включить автозапуск Docker"
                [ERROR_DOCKER_NOT_WORKING]="Docker работает некорректно"
                [ERROR_CONFIGURE_UFW]="Не удалось настроить UFW"
                [ERROR_CONFIGURE_UPGRADES]="Не удалось настроить автообновления"
                [ERROR_DOCKER_DNS]="Не удалось разрешить download.docker.com. Проверьте настройки DNS."
                [ERROR_INSTALL_CERTBOT]="Не удалось установить certbot"
                [SUCCESS_INSTALL]="Все пакеты успешно установлены"

                # First-run setup / Первоначальная установка
                [SETUP_COPYING_SCRIPT]="Скрипт скопирован в постоянное место: %s"
                [SETUP_CMD_WARN]="Не удалось создать команду 'socks'"
                [SETUP_INSTALLING]="Установка SOCKS5 MANAGER"
                [SETUP_DONE]="Менеджер SOCKS5 прокси успешно установлен!"
                [SETUP_CREATE_FIRST]="Создать первый профиль сейчас? [Y/n]: "

                # Dependency installation / Установка зависимостей
                [DEPS_UPDATING]="Обновление пакетов и установка зависимостей..."
                [DEPS_ERROR]="Ошибка при установке пакетов"

                # Reinstall / Переустановка
                [REINSTALL_TITLE]="ПЕРЕУСТАНОВКА SOCKS5 МЕНЕДЖЕРА"
                [REINSTALL_WARNING]="ВНИМАНИЕ: Все профили и конфигурации будут УДАЛЕНЫ!"
                [REINSTALL_CONFIRM]="Вы уверены? Введите 'YES' для подтверждения: "
                [REINSTALL_CANCELLED]="Переустановка отменена"
                [REINSTALL_REMOVING]="Удаление старой установки..."
                [REINSTALL_DONE]="Переустановка успешно завершена!"

                # Main menu / Главное меню
                [MENU_TITLE]="SOCKS5 PROXY MANAGER by distillium"
                [MENU_SHOW]="Показать все подключения"
                [MENU_CREATE]="Создать новое подключение"
                [MENU_DELETE]="Удалить подключение"
                [MENU_UNINSTALL]="Удалить менеджер и все конфигурации"
                [MENU_EXIT]="Выход"
                [MENU_PROMPT]="Выберите пункт меню (0-4): "
                [MENU_QUICKSTART]="Быстрый запуск: 'socks' доступен из любой точки системы"
                [MENU_INVALID]="Неверный выбор. Попробуйте снова."
                [MENU_GOODBYE]="До свидания!"

                # Profile creation / Создание профиля
                [CREATE_TITLE]="СОЗДАНИЕ НОВОГО SOCKS5 ПРОФИЛЯ"
                [CREATE_NAME_PROMPT]="Введите название профиля (Enter для автогенерации): "
                [CREATE_GENERATING]="Создается профиль: %s"
                [CREATE_PROFILE_EXISTS]="Профиль '%s' уже существует!"
                [CREATE_IFACE_DETECTED]="Обнаружен сетевой интерфейс: %s"
                [CREATE_AUTH_TITLE]="НАСТРОЙКА АУТЕНТИФИКАЦИИ"
                [CREATE_AUTH_MANUAL]="Ввести логин и пароль вручную? [y/N]: "
                [CREATE_USERNAME_PROMPT]="Имя пользователя: "
                [CREATE_PASSWORD_PROMPT]="Пароль: "
                [CREATE_CREDS_GENERATED]="Сгенерированы учетные данные:"
                [CREATE_CREDS_LOGIN]="  Логин:   %s"
                [CREATE_CREDS_PASS]="  Пароль:  %s"
                [CREATE_PORT_TITLE]="НАСТРОЙКА ПОРТА"
                [CREATE_PORT_MANUAL]="Указать порт вручную? [y/N]: "
                [CREATE_PORT_PROMPT]="Введите порт (1024-65535): "
                [CREATE_PORT_INVALID]="Порт недоступен или некорректный. Попробуйте снова."
                [CREATE_PORT_ASSIGNED]="Назначен порт: %s"
                [CREATE_SYS_USER]="Создание системного пользователя..."
                [CREATE_UPDATE_DANTE]="Обновление конфигурации Dante..."
                [CREATE_SETUP_FW]="Настройка брандмауэра..."
                [CREATE_RESTARTING]="Перезапуск службы..."
                [CREATE_DANTE_FAIL]="Не удалось запустить службу Dante. Проверьте: journalctl -u danted"
                [CREATE_SUCCESS_TITLE]="ПРОФИЛЬ СОЗДАН УСПЕШНО"
                [CREATE_SUCCESS_MSG]="SOCKS5 прокси-сервер '%s' настроен!"
                [CREATE_CONN_TITLE]="Параметры подключения:"
                [CREATE_CONN_NAME]="  Название: %s"
                [CREATE_CONN_IP]="  IP адрес: %s"
                [CREATE_CONN_PORT]="  Порт:     %s"
                [CREATE_CONN_LOGIN]="  Логин:    %s"
                [CREATE_CONN_PASS]="  Пароль:   %s"
                [CREATE_ANTIDETECT_TITLE]="Форматы для антидетект браузеров:"

                # Profile list / Список профилей
                [SHOW_TITLE]="АКТИВНЫЕ SOCKS5 ПОДКЛЮЧЕНИЯ"
                [SHOW_NO_PROFILES]="Нет созданных профилей"
                [SHOW_LIST_TITLE]="Список профилей:"
                [SHOW_PROFILE_ITEM]="%d. %s (порт: %s)"
                [SHOW_BACK]="Назад в главное меню"
                [SHOW_SELECT_PROMPT]="Выберите профиль для просмотра (0-%d): "
                [SHOW_INVALID]="Неверный выбор"
                [SHOW_INFO_TITLE]="ИНФОРМАЦИЯ О ПРОФИЛЕ: %s"
                [SHOW_CONN_TITLE]="Параметры подключения:"
                [SHOW_STATUS_ACTIVE]="АКТИВЕН"
                [SHOW_STATUS_STOPPED]="ОСТАНОВЛЕН"
                [SHOW_CONN_STATUS]="  Статус:   %s"
                [SHOW_CONN_CREATED]="  Создан:   %s"
                [SHOW_ANTIDETECT_TITLE]="Форматы для антидетект браузеров:"
                [SHOW_BACK_PROMPT]="Нажмите Enter для возврата к списку..."

                # Profile deletion / Удаление профиля
                [DELETE_TITLE]="УДАЛЕНИЕ SOCKS5 ПРОФИЛЯ"
                [DELETE_NO_PROFILES]="Нет профилей для удаления"
                [DELETE_AVAILABLE]="Доступные профили:"
                [DELETE_NAME_PROMPT]="Введите название профиля для удаления: "
                [DELETE_NAME_EMPTY]="Название профиля не указано"
                [DELETE_NOT_FOUND]="Профиль '%s' не найден"
                [DELETE_CONFIRM]="Вы уверены, что хотите удалить профиль '%s'? [y/N]: "
                [DELETE_CANCELLED]="Удаление отменено"
                [DELETE_DELETING]="Удаление профиля '%s'..."
                [DELETE_UPDATE_DANTE]="Обновление конфигурации Dante..."
                [DELETE_LAST_PROFILE]="Это был последний профиль. Остановка службы Dante."
                [DELETE_SUCCESS]="Профиль '%s' успешно удален"

                # Full uninstall / Полное удаление
                [UNINSTALL_TITLE]="ПОЛНОЕ УДАЛЕНИЕ SOCKS5 МЕНЕДЖЕРА"
                [UNINSTALL_WARNING]="ВНИМАНИЕ: Будут удалены ВСЕ профили, конфигурации и сам скрипт!"
                [UNINSTALL_CONFIRM]="Вы уверены? Введите 'YES' для подтверждения: "
                [UNINSTALL_CANCELLED]="Удаление отменено"
                [UNINSTALL_REMOVING]="Удаление всех профилей, конфигураций и файлов скрипта..."
                [UNINSTALL_SUCCESS]="SOCKS5 менеджер полностью удалён из системы"

                # Common / Общие
                [PRESS_ENTER]="Нажмите Enter для продолжения..."
                [USAGE]="Использование: socks [menu|list|create|delete|reinstall|uninstall]"
                [USAGE_LIST]="  list      - показать все подключения"
                [USAGE_CREATE]="  create    - создать новое подключение"
                [USAGE_DELETE]="  delete    - удалить подключение"
                [USAGE_REINSTALL]="  reinstall - переустановить менеджер (все данные будут удалены)"
                [USAGE_UNINSTALL]="  uninstall - полностью удалить менеджер из системы"
            )
            ;;
    esac
}

# Translate helper with printf substitution / Хелпер перевода с подстановкой через printf
# Usage / Использование: t KEY [arg1 arg2 ...]
t() {
    local key="$1"
    shift
    printf "${LANG[$key]}" "$@"
}

# Load saved language from file / Загрузить сохранённый язык из файла
load_language() {
    if [ -f "$LANG_FILE" ]; then
        local saved_lang
        saved_lang=$(cat "$LANG_FILE")
        case $saved_lang in
            1) set_language en ;;
            2) set_language ru ;;
            *)
                # Corrupt file — remove and re-ask / Повреждённый файл — удалить и спросить снова
                rm -f "$LANG_FILE"
                return 1
                ;;
        esac
        return 0
    fi
    return 1  # File not found / Файл не найден
}

# Interactive language selection screen / Интерактивный экран выбора языка
choose_language() {
    clear
    # Bilingual prompt — language not yet known / Двуязычная подсказка — язык ещё не выбран
    echo -e "${COLOR_GREEN}Select language / Выберите язык:${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_YELLOW}1. English${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}2. Русский${COLOR_RESET}"
    echo ""

    local choice
    while true; do
        read -p "> " choice
        case $choice in
            1)
                set_language en
                mkdir -p "$MANAGER_DIR"
                echo "1" > "$LANG_FILE"
                break
                ;;
            2)
                set_language ru
                mkdir -p "$MANAGER_DIR"
                echo "2" > "$LANG_FILE"
                break
                ;;
            *)
                echo -e "${COLOR_RED}1 or 2 / 1 или 2${COLOR_RESET}"
                ;;
        esac
    done
}


# ─────────────────────────────────────────────
#        PRINT HELPERS / ХЕЛПЕРЫ ВЫВОДА
# ─────────────────────────────────────────────

# Informational message / Информационное сообщение
print_status()  { echo -e "${COLOR_GREEN}[INFO]${COLOR_RESET} $1"; }

# Non-critical warning / Некритическое предупреждение
print_warning() { echo -e "${COLOR_YELLOW}[WARNING]${COLOR_RESET} $1"; }

# Error message / Сообщение об ошибке
print_error()   { echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $1"; }

# Section header / Заголовок секции
print_header()  { echo -e "${COLOR_BLUE}$1${COLOR_RESET}"; }

# Success message / Сообщение об успехе
print_success() { echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $1"; }


# ─────────────────────────────────────────────
#        CORE FUNCTIONS / ОСНОВНЫЕ ФУНКЦИИ
# ─────────────────────────────────────────────

# Ensure manager dir and valid profiles.json always exist
# Гарантировать наличие директории и валидного profiles.json — ВСЕГДА
init_manager() {
    # Always create directory (not only on first run)
    # Всегда создавать директорию (не только при первом запуске)
    mkdir -p "$MANAGER_DIR"

    # Create profiles file if missing / Создать файл профилей если отсутствует
    if [ ! -f "$PROFILES_FILE" ]; then
        echo "[]" > "$PROFILES_FILE"
    else
        # Validate and reset corrupt file / Проверить и сбросить повреждённый файл
        if ! jq -e 'type == "array"' "$PROFILES_FILE" > /dev/null 2>&1; then
            print_warning "profiles.json corrupt, resetting / profiles.json повреждён, сброс"
            echo "[]" > "$PROFILES_FILE"
        fi
    fi

    setup_socks_command
}

# Install script to /usr/local/bin and (re)create 'socks' symlink
# Установить скрипт в /usr/local/bin и (пере)создать симлинк 'socks'
setup_socks_command() {
    # Resolve real path of currently running script
    # Определить реальный путь текущего скрипта
    local source_script
    if [ -n "${BASH_SOURCE[0]}" ]; then
        source_script="$(readlink -f "${BASH_SOURCE[0]}")"
    else
        source_script="$(readlink -f "$0")"
    fi

    # Copy to target only if source differs from target
    # Копировать если источник отличается от цели
    if [ ! -f "$SCRIPT_TARGET" ] || ! cmp -s "$source_script" "$SCRIPT_TARGET"; then
        cp "$source_script" "$SCRIPT_TARGET"
        chmod +x "$SCRIPT_TARGET"
        print_status "$(t SETUP_COPYING_SCRIPT "$SCRIPT_TARGET")"
    fi

    # Always recreate symlink to ensure freshness / Всегда пересоздавать симлинк
    rm -f "$SCRIPT_PATH"
    ln -s "$SCRIPT_TARGET" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"

    if [ ! -x "$SCRIPT_PATH" ]; then
        print_warning "$(t SETUP_CMD_WARN)"
    fi
}

# Install dante-server and jq via apt / Установить dante-server и jq через apt
install_dependencies() {
    print_status "$(t DEPS_UPDATING)"
    apt-get update > /dev/null 2>&1
    apt-get install -y dante-server jq > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        print_error "$(t DEPS_ERROR)"
        exit 1
    fi
}

# Generate a random free port in range 1024–65535
# Сгенерировать случайный свободный порт в диапазоне 1024–65535
generate_random_port() {
    local port
    while :; do
        port=$((RANDOM % 64512 + 1024))
        # Check both system sockets and existing profiles
        # Проверить занятость как в системе, так и в профилях
        if ! ss -tulnp | awk '{print $4}' | grep -q ":$port" \
           && ! is_port_used_by_profiles "$port"; then
            echo "$port"
            return
        fi
    done
}

# Check if a port is already used by any saved profile
# Проверить, занят ли порт каким-либо сохранённым профилем
is_port_used_by_profiles() {
    local check_port=$1
    if [ -f "$PROFILES_FILE" ]; then
        jq -r '.[].port' "$PROFILES_FILE" 2>/dev/null | grep -q "^$check_port$"
    else
        return 1
    fi
}

# Return next available sequential profile number (socks5-N)
# Вернуть следующий доступный порядковый номер профиля (socks5-N)
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

# Rebuild /etc/danted.conf from current profiles list
# Перестроить /etc/danted.conf из текущего списка профилей
generate_dante_config() {
    local INTERFACE
    INTERFACE=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5}' | head -n 1)

    if [ -z "$INTERFACE" ]; then
        print_error "Could not detect network interface / Не удалось определить сетевой интерфейс"
        return 1
    fi

    # Guard: Dante requires at least one internal listener
    # Защита: Dante требует хотя бы один internal
    local profile_count=0
    [ -f "$PROFILES_FILE" ] && profile_count=$(jq 'length' "$PROFILES_FILE" 2>/dev/null || echo 0)

    if [ "$profile_count" -eq 0 ]; then
        print_warning "No profiles — skipping Dante config / Нет профилей — пропуск конфига Dante"
        return 1
    fi

    # Write static header / Записать статический заголовок
    cat > "$DANTE_CONFIG" <<EOL
logoutput: /var/log/danted.log
user.privileged: root
user.notprivileged: nobody

EOL

    # Add one internal listener per profile port
    # Добавить один internal-слушатель на каждый порт профиля
    while IFS= read -r profile; do
        local port
        port=$(echo "$profile" | jq -r '.port')
        echo "internal: 0.0.0.0 port = $port" >> "$DANTE_CONFIG"
    done < <(jq -c '.[]' "$PROFILES_FILE")

    # Write static footer with auth and routing rules
    # Записать статический footer с правилами авторизации и маршрутизации
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

# Append a new profile entry to profiles.json atomically
# Атомарно добавить новую запись профиля в profiles.json
save_profile() {
    local name=$1
    local port=$2
    local username=$3
    local password=$4

    # Safety net: ensure file exists before jq read
    # Страховка: файл должен существовать перед чтением jq
    [ ! -f "$PROFILES_FILE" ] && echo "[]" > "$PROFILES_FILE"

    local new_profile
    new_profile=$(jq -n \
        --arg name     "$name" \
        --arg port     "$port" \
        --arg username "$username" \
        --arg password "$password" \
        --arg created  "$(date -Iseconds)" \
        '{
            name: $name,
            port: ($port | tonumber),
            username: $username,
            password: $password,
            created: $created
        }')

    # Write to temp file then atomically replace
    # Записать во временный файл, затем атомарно заменить
    jq ". + [$new_profile]" "$PROFILES_FILE" > "$PROFILES_FILE.tmp" \
        && mv "$PROFILES_FILE.tmp" "$PROFILES_FILE"
}

# Return 0 if profile name already exists in profiles.json
# Вернуть 0, если профиль с таким именем уже существует в profiles.json
profile_exists() {
    local name=$1
    if [ -f "$PROFILES_FILE" ]; then
        jq -e ".[] | select(.name == \"$name\")" "$PROFILES_FILE" > /dev/null 2>&1
    else
        return 1
    fi
}

# Remove all OS users and firewall rules from all saved profiles
# Удалить всех системных пользователей и правила брандмауэра всех профилей
purge_all_profiles() {
    if [ -f "$PROFILES_FILE" ]; then
        while IFS= read -r profile; do
            local username port
            username=$(echo "$profile" | jq -r '.username')
            port=$(echo "$profile"     | jq -r '.port')
            userdel "$username" 2>/dev/null
            ufw delete allow "$port/tcp" > /dev/null 2>&1
        done < <(jq -c '.[]' "$PROFILES_FILE" 2>/dev/null)
    fi
}


# ─────────────────────────────────────────────
#         PROFILE COMMANDS / КОМАНДЫ ПРОФИЛЕЙ
# ─────────────────────────────────────────────

# Interactive wizard to create a new SOCKS5 profile
# Интерактивный мастер создания нового SOCKS5 профиля
create_profile() {
    print_header "$(t CREATE_TITLE)"
    echo ""

    # ── Profile name ── / ── Имя профиля ──
    read -p "$(t CREATE_NAME_PROMPT)" profile_name
    if [ -z "$profile_name" ]; then
        local next_num
        next_num=$(get_next_profile_number)
        profile_name="socks5-$next_num"
        print_status "$(t CREATE_GENERATING "$profile_name")"
    fi

    if profile_exists "$profile_name"; then
        print_error "$(t CREATE_PROFILE_EXISTS "$profile_name")"
        return 1
    fi

    # ── Detect outbound interface ── / ── Определить исходящий интерфейс ──
    local INTERFACE
    INTERFACE=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5}' | head -n 1)
    print_status "$(t CREATE_IFACE_DETECTED "$INTERFACE")"

    echo ""
    print_header "$(t CREATE_AUTH_TITLE)"

    # ── Credentials: manual or auto-generated ── / ── Учётные данные: вручную или авто ──
    local username password
    read -p "$(t CREATE_AUTH_MANUAL)" choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        read -p "$(t CREATE_USERNAME_PROMPT)" username
        read -s -p "$(t CREATE_PASSWORD_PROMPT)" password
        echo ""
    else
        username=$(tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 8)
        password=$(tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 12)
        # Use t() directly with value — avoids double-printf bug
        # Передавать значение прямо в t() — избегает бага двойного printf
        print_status "$(t CREATE_CREDS_GENERATED)"
        echo "$(t CREATE_CREDS_LOGIN "$username")"
        echo "$(t CREATE_CREDS_PASS  "$password")"
    fi

    echo ""
    print_header "$(t CREATE_PORT_TITLE)"

    # ── Port: manual or auto-generated ── / ── Порт: вручную или авто ──
    local port
    read -p "$(t CREATE_PORT_MANUAL)" port_choice
    if [[ "$port_choice" =~ ^[Yy]$ ]]; then
        while :; do
            read -p "$(t CREATE_PORT_PROMPT)" port
            if [[ "$port" =~ ^[0-9]+$ ]] \
               && [ "$port" -ge 1024 ] && [ "$port" -le 65535 ] \
               && ! ss -tulnp | awk '{print $4}' | grep -q ":$port" \
               && ! is_port_used_by_profiles "$port"; then
                break
            else
                print_warning "$(t CREATE_PORT_INVALID)"
            fi
        done
    else
        port=$(generate_random_port)
        print_status "$(t CREATE_PORT_ASSIGNED "$port")"
    fi

    # ── Create OS user for Dante auth ── / ── Создать системного пользователя для авторизации Dante ──
    print_status "$(t CREATE_SYS_USER)"
    useradd -r -s /bin/false "$username" 2>/dev/null
    # Try chpasswd first (faster), fallback to passwd
    # Сначала chpasswd (быстрее), fallback на passwd
    echo "$username:$password" | chpasswd 2>/dev/null || \
        (echo "$password"; echo "$password") | passwd "$username" > /dev/null 2>&1

    # ── Persist profile and regenerate config ── / ── Сохранить профиль и перегенерировать конфиг ──
    save_profile "$profile_name" "$port" "$username" "$password"

    print_status "$(t CREATE_UPDATE_DANTE)"
    generate_dante_config

    # ── Open port in firewall ── / ── Открыть порт в брандмауэре ──
    print_status "$(t CREATE_SETUP_FW)"
    ufw allow proto tcp from 0.0.0.0/0 to any port "$port" > /dev/null 2>&1

    # ── Restart Dante ── / ── Перезапустить Dante ──
    print_status "$(t CREATE_RESTARTING)"
    systemctl restart danted
    systemctl enable danted > /dev/null 2>&1

    if ! systemctl is-active --quiet danted; then
        print_error "$(t CREATE_DANTE_FAIL)"
        return 1
    fi

    # ── Fetch external IP for connection info ── / ── Получить внешний IP для отображения данных ──
    local external_ip
    external_ip=$(curl -4 -s --max-time 5 ifconfig.me 2>/dev/null || echo "N/A")

    echo ""
    print_header "$(t CREATE_SUCCESS_TITLE)"
    print_success "$(t CREATE_SUCCESS_MSG "$profile_name")"
    echo ""
    echo -e "${COLOR_BLUE}$(t CREATE_CONN_TITLE)${COLOR_RESET}"
    # Pass value directly into t() — fixes missing output bug
    # Передаём значение прямо в t() — исправляет баг пустого вывода
    echo "$(t CREATE_CONN_NAME  "$profile_name")"
    echo "$(t CREATE_CONN_IP    "$external_ip")"
    echo "$(t CREATE_CONN_PORT  "$port")"
    echo "$(t CREATE_CONN_LOGIN "$username")"
    echo "$(t CREATE_CONN_PASS  "$password")"
    echo ""
    echo -e "${COLOR_BLUE}$(t CREATE_ANTIDETECT_TITLE)${COLOR_RESET}"
    echo "  $external_ip:$port:$username:$password"
    echo "  $username:$password@$external_ip:$port"
    echo ""
}

# Display all profiles, then show detailed info for selected one
# Отобразить все профили, затем показать подробности по выбранному
show_connections() {
    print_header "$(t SHOW_TITLE)"

    if [ ! -f "$PROFILES_FILE" ] || [ "$(jq length "$PROFILES_FILE" 2>/dev/null)" -eq 0 ]; then
        print_warning "$(t SHOW_NO_PROFILES)"
        return
    fi

    local external_ip
    external_ip=$(curl -4 -s --max-time 5 ifconfig.me 2>/dev/null || echo "N/A")

    # Determine Dante service status / Определить статус службы Dante
    local service_status
    if systemctl is-active --quiet danted; then
        service_status="${COLOR_GREEN}$(t SHOW_STATUS_ACTIVE)${COLOR_RESET}"
    else
        service_status="${COLOR_RED}$(t SHOW_STATUS_STOPPED)${COLOR_RESET}"
    fi

    echo ""
    echo -e "${COLOR_BLUE}$(t SHOW_LIST_TITLE)${COLOR_RESET}"
    echo ""

    local counter=1
    declare -a profile_names=()  # Index array for selection / Индексный массив для выбора

    while IFS= read -r profile; do
        local name port
        name=$(echo "$profile" | jq -r '.name')
        port=$(echo "$profile" | jq -r '.port')
        profile_names+=("$name")
        # Pass all args into t() directly / Передать все аргументы прямо в t()
        echo -e "${COLOR_BLUE}$(t SHOW_PROFILE_ITEM "$counter" "$name" "$port")${COLOR_RESET}"
        ((counter++))
    done < <(jq -c '.[]' "$PROFILES_FILE")

    echo ""
    echo -e "${COLOR_BLUE}0.${COLOR_RESET} $(t SHOW_BACK)"
    echo ""

    local selection
    read -p "$(t SHOW_SELECT_PROMPT "$((counter-1))")" selection

    # Handle back / Обработать возврат
    if [[ "$selection" == "0" ]]; then
        return
    fi

    # Validate numeric input range / Проверить числовой ввод в допустимом диапазоне
    if ! [[ "$selection" =~ ^[1-9][0-9]*$ ]] \
       || [ "$selection" -lt 1 ] || [ "$selection" -ge "$counter" ]; then
        print_error "$(t SHOW_INVALID)"
        sleep 1
        return
    fi

    # Extract profile data by index / Извлечь данные профиля по индексу
    local selected_profile="${profile_names[$((selection-1))]}"
    local profile_data
    profile_data=$(jq ".[] | select(.name == \"$selected_profile\")" "$PROFILES_FILE")

    local name port username password created
    name=$(echo "$profile_data"     | jq -r '.name')
    port=$(echo "$profile_data"     | jq -r '.port')
    username=$(echo "$profile_data" | jq -r '.username')
    password=$(echo "$profile_data" | jq -r '.password')
    created=$(echo "$profile_data"  | jq -r '.created')

    clear
    print_header "$(t SHOW_INFO_TITLE "$name")"
    echo ""
    echo -e "${COLOR_BLUE}$(t SHOW_CONN_TITLE)${COLOR_RESET}"
    # Pass value directly into t() — fixes missing output bug
    # Передаём значение прямо в t() — исправляет баг пустого вывода
    echo "$(t CREATE_CONN_NAME  "$name")"
    echo "$(t CREATE_CONN_IP    "$external_ip")"
    echo "$(t CREATE_CONN_PORT  "$port")"
    echo "$(t CREATE_CONN_LOGIN "$username")"
    echo "$(t CREATE_CONN_PASS  "$password")"
    echo -e "$(t SHOW_CONN_STATUS  "$(echo -e "$service_status")")"
    echo "$(t SHOW_CONN_CREATED "$created")"
    echo ""
    echo -e "${COLOR_BLUE}$(t SHOW_ANTIDETECT_TITLE)${COLOR_RESET}"
    echo "  $external_ip:$port:$username:$password"
    echo "  $username:$password@$external_ip:$port"
    echo ""

    read -p "$(t SHOW_BACK_PROMPT)"
    clear
    show_connections  # Recurse back to list / Рекурсивно вернуться к списку
}

# Interactive profile deletion with confirmation
# Интерактивное удаление профиля с подтверждением
delete_profile() {
    print_header "$(t DELETE_TITLE)"

    if [ ! -f "$PROFILES_FILE" ] || [ "$(jq length "$PROFILES_FILE" 2>/dev/null)" -eq 0 ]; then
        print_warning "$(t DELETE_NO_PROFILES)"
        return
    fi

    echo ""
    echo "$(t DELETE_AVAILABLE)"
    jq -r '.[] | "  - \(.name) (port: \(.port))"' "$PROFILES_FILE"
    echo ""

    local profile_name
    read -p "$(t DELETE_NAME_PROMPT)" profile_name

    if [ -z "$profile_name" ]; then
        print_warning "$(t DELETE_NAME_EMPTY)"
        return
    fi

    if ! profile_exists "$profile_name"; then
        print_error "$(t DELETE_NOT_FOUND "$profile_name")"
        return
    fi

    # Fetch username and port before removing from JSON
    # Получить имя пользователя и порт до удаления из JSON
    local profile_data
    profile_data=$(jq ".[] | select(.name == \"$profile_name\")" "$PROFILES_FILE")
    local username port
    username=$(echo "$profile_data" | jq -r '.username')
    port=$(echo "$profile_data"     | jq -r '.port')

    echo ""
    local confirm
    read -p "$(t DELETE_CONFIRM "$profile_name")" confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_warning "$(t DELETE_CANCELLED)"
        return
    fi

    print_status "$(t DELETE_DELETING "$profile_name")"

    # Remove OS user created for this profile / Удалить системного пользователя профиля
    userdel "$username" 2>/dev/null

    # Close firewall port / Закрыть порт в брандмауэре
    ufw delete allow "$port/tcp" > /dev/null 2>&1

    # Remove profile from JSON atomically / Атомарно удалить профиль из JSON
    jq "del(.[] | select(.name == \"$profile_name\"))" "$PROFILES_FILE" > "$PROFILES_FILE.tmp" \
        && mv "$PROFILES_FILE.tmp" "$PROFILES_FILE"

    print_status "$(t DELETE_UPDATE_DANTE)"

    # Keep Dante running if profiles remain, else stop it
    # Оставить Dante запущенным если профили есть, иначе остановить
    if [ "$(jq length "$PROFILES_FILE" 2>/dev/null)" -gt 0 ]; then
        generate_dante_config
        systemctl restart danted
    else
        print_warning "$(t DELETE_LAST_PROFILE)"
        systemctl stop danted
        rm -f "$DANTE_CONFIG"  # Remove empty config / Удалить пустой конфиг
    fi

    print_success "$(t DELETE_SUCCESS "$profile_name")"
}

# Remove everything: profiles, users, firewall rules, Dante, script files
# Удалить всё: профили, пользователей, правила брандмауэра, Dante, файлы скрипта
uninstall_manager() {
    print_header "$(t UNINSTALL_TITLE)"

    echo ""
    echo -e "${COLOR_RED}$(t UNINSTALL_WARNING)${COLOR_RESET}"
    echo ""

    local confirm
    read -p "$(t UNINSTALL_CONFIRM)" confirm

    # Require exact string "YES" to prevent accidental deletion
    # Требовать точную строку "YES" для предотвращения случайного удаления
    if [ "$confirm" != "YES" ]; then
        print_warning "$(t UNINSTALL_CANCELLED)"
        return
    fi

    print_status "$(t UNINSTALL_REMOVING)"

    systemctl stop    danted 2>/dev/null
    systemctl disable danted 2>/dev/null

    # Clean up OS users and firewall rules for each profile
    # Очистить системных пользователей и правила брандмауэра для каждого профиля
    purge_all_profiles

    # Remove all manager and script files / Удалить все файлы менеджера и скрипта
    rm -rf "$MANAGER_DIR"
    rm -f  "$DANTE_CONFIG"
    rm -f  "$SCRIPT_PATH"
    rm -f  "$SCRIPT_TARGET"
    DEBIAN_FRONTEND=noninteractive apt-get --purge remove -y dante-server > /dev/null 2>&1

    print_success "$(t UNINSTALL_SUCCESS)"
    echo ""
    exit 0  # Script files are gone — must exit / Файлы удалены — выход обязателен
}

# Wipe everything and reinstall from scratch
# Стереть всё и переустановить с нуля
reinstall_manager() {
    print_header "$(t REINSTALL_TITLE)"

    echo ""
    echo -e "${COLOR_RED}$(t REINSTALL_WARNING)${COLOR_RESET}"
    echo ""

    local confirm
    read -p "$(t REINSTALL_CONFIRM)" confirm

    # Require exact string "YES" / Требовать точную строку "YES"
    if [ "$confirm" != "YES" ]; then
        print_warning "$(t REINSTALL_CANCELLED)"
        return
    fi

    print_status "$(t REINSTALL_REMOVING)"

    systemctl stop    danted 2>/dev/null
    systemctl disable danted 2>/dev/null

    purge_all_profiles

    # Remove data and config, but keep the script binary
    # Удалить данные и конфиги, но сохранить бинарник скрипта
    rm -rf "$MANAGER_DIR"
    rm -f  "$DANTE_CONFIG"
    DEBIAN_FRONTEND=noninteractive apt-get --purge remove -y dante-server > /dev/null 2>&1

    # Reinstall deps fresh / Переустановить зависимости заново
    install_dependencies

    # Re-init with fresh language selection / Заново инициализировать с выбором языка
    choose_language
    init_manager
    # No profiles yet — config will be generated after first profile creation
    # Профилей ещё нет — конфиг сгенерируется после создания первого профиля

    print_success "$(t REINSTALL_DONE)"
    echo ""

    local create_first
    read -p "$(t SETUP_CREATE_FIRST)" create_first
    if [[ ! "$create_first" =~ ^[Nn]$ ]]; then
        clear
        create_profile
        echo ""
        read -p "$(t PRESS_ENTER)"
    fi

    show_main_menu
}


# ─────────────────────────────────────────────
#          MAIN MENU / ГЛАВНОЕ МЕНЮ
# ─────────────────────────────────────────────

show_main_menu() {
    while true; do
        clear
        print_header "$(t MENU_TITLE)"
        echo ""
        echo -e "${COLOR_BLUE}1.${COLOR_RESET} $(t MENU_SHOW)"
        echo -e "${COLOR_BLUE}2.${COLOR_RESET} $(t MENU_CREATE)"
        echo ""
        echo -e "${COLOR_BLUE}3.${COLOR_RESET} $(t MENU_DELETE)"
        echo -e "${COLOR_BLUE}4.${COLOR_RESET} $(t MENU_UNINSTALL)"
        echo ""
        echo -e "${COLOR_BLUE}0.${COLOR_RESET} $(t MENU_EXIT)"
        echo ""
        read -p "$(t MENU_PROMPT)" choice
        echo -e "${COLOR_GRAY}–  $(t MENU_QUICKSTART)${COLOR_RESET}"

        case $choice in
            1)
                clear; show_connections
                echo ""
                read -p "$(t PRESS_ENTER)"
                ;;
            2)
                clear; create_profile
                echo ""
                read -p "$(t PRESS_ENTER)"
                ;;
            3)
                clear; delete_profile
                echo ""
                read -p "$(t PRESS_ENTER)"
                ;;
            4)
                clear; uninstall_manager
                ;;
            0)
                echo ""
                print_status "$(t MENU_GOODBYE)"
                exit 0
                ;;
            *)
                print_error "$(t MENU_INVALID)"
                sleep 1
                ;;
        esac
    done
}


# ─────────────────────────────────────────────
#          ENTRYPOINT / ТОЧКА ВХОДА
# ─────────────────────────────────────────────

# Root check helper / Вспомогательная проверка root
require_root() {
    if [[ $EUID -ne 0 ]]; then
        # Language may not be loaded yet — bilingual message
        # Язык может быть ещё не загружен — двуязычное сообщение
        echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} Must be run as root / Требуются права root"
        exit 1
    fi
}

main() {
    require_root

    if [ ! -d "$MANAGER_DIR" ] || [ ! -f "$PROFILES_FILE" ]; then
        # ── First run or broken install ──
        # ── Первый запуск или сломанная установка ──
        choose_language
        print_status "$(t SETUP_INSTALLING)"
        install_dependencies
        init_manager
        # No profiles yet — skip dante config / Профилей нет — пропустить конфиг Dante
        rm -f /root/install.sh   # Remove bootstrap installer / Удалить загрузочный инсталлятор
        echo ""
        print_success "$(t SETUP_DONE)"
        echo ""
        local create_first
        read -p "$(t SETUP_CREATE_FIRST)" create_first
        if [[ ! "$create_first" =~ ^[Nn]$ ]]; then
            clear
            create_profile
            echo ""
            read -p "$(t PRESS_ENTER)"
        fi
    else
        # ── Subsequent run: load saved language ──
        # ── Повторный запуск: загрузить сохранённый язык ──
        if ! load_language; then
            choose_language   # Re-ask if lang file was lost / Спросить снова если файл утерян
        fi
        setup_socks_command
    fi

    show_main_menu
}

# ─── CLI argument dispatcher / Диспетчер аргументов CLI ───
case "${1:-}" in
    ""|menu)
        main
        ;;
    list)
        # Load language with en fallback / Загрузить язык с fallback на en
        if ! load_language; then set_language en; fi
        init_manager
        show_connections
        ;;
    create)
        require_root
        if ! load_language; then set_language en; fi
        init_manager
        create_profile
        ;;
    delete)
        require_root
        if ! load_language; then set_language en; fi
        init_manager
        delete_profile
        ;;
    reinstall)
        require_root
        if ! load_language; then set_language en; fi
        reinstall_manager
        ;;
    uninstall)
        require_root
        if ! load_language; then set_language en; fi
        uninstall_manager
        ;;
    *)
        # Unknown argument — show usage / Неизвестный аргумент — показать справку
        if ! load_language; then set_language en; fi
        echo "$(t USAGE)"
        echo "$(t USAGE_LIST)"
        echo "$(t USAGE_CREATE)"
        echo "$(t USAGE_DELETE)"
        echo "$(t USAGE_REINSTALL)"
        echo "$(t USAGE_UNINSTALL)"
        exit 1
        ;;
esac
