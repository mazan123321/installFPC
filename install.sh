#!/data/data/com.termux/files/usr/bin/bash

GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
CYAN='\033[36m'
RESET='\033[0m'

echo -e "${GREEN}"
echo "Установщик создан @exfador, адаптирован для Termux teepuck${RESET}"
echo "Особенности установщика в Termux:"
echo "1. Оптимизирован под Android-окружение"
echo "2. Использует screen для управления ботом"
echo "3. Упрощенная установка без лишних зависимостей"
echo "4. Автоматическая настройка окружения Termux"
echo -e "${RESET}"

# Обновление репозиториев Termux
echo -e "${GREEN}Обновляю пакеты Termux...${RESET}"
if ! pkg update -y ; then
    echo -e "${RED}Ошибка при обновлении пакетов Termux.${RESET}"
    exit 2
fi

# Установка необходимых пакетов
echo -e "${GREEN}Устанавливаю необходимые пакеты...${RESET}"
if ! pkg install -y python curl unzip screen jq ; then
    echo -e "${RED}Ошибка при установке необходимых пакетов.${RESET}"
    exit 2
fi

# Создание рабочей директории
echo -e "${GREEN}Создаю рабочую директорию...${RESET}"
WORK_DIR="$HOME/FunPayCardinal"
mkdir -p "$WORK_DIR"

# Получение списка версий
echo -e "${GREEN}Получаю список доступных версий FunPayCardinal...${RESET}"
gh_repo="sidor0912/FunPayCardinal"
releases=$(curl -sS https://api.github.com/repos/$gh_repo/releases | grep "tag_name" | awk '{print $2}' | sed 's/"//g' | sed 's/,//g')

if [ -z "$releases" ]; then
    echo -e "${RED}Не удалось получить список версий с GitHub. Использую последнюю версию.${RESET}"
    use_latest="true"
else
    echo -e "${YELLOW}Доступные версии FunPayCardinal:${RESET}"
    versions=($releases)
    for i in "${!versions[@]}"; do
        echo "$i) ${versions[$i]}"
    done
    echo "latest) Последняя версия (по умолчанию)"
    
    echo -n -e "${YELLOW}Выберите версию (введите номер или 'latest'): ${RESET}"
    read version_choice
    if [[ "$version_choice" == "latest" || -z "$version_choice" ]]; then
        use_latest="true"
    elif [[ "$version_choice" =~ ^[0-9]+$ && $version_choice -ge 0 && $version_choice -lt ${#versions[@]} ]]; then
        selected_version=${versions[$version_choice]}
        echo -e "${GREEN}Выбрана версия: $selected_version${RESET}"
    else
        echo -e "${RED}Неверный выбор. Использую последнюю версию.${RESET}"
        use_latest="true"
    fi
fi

# Загрузка и установка FunPayCardinal
echo -e "${GREEN}Устанавливаю FunPayCardinal...${RESET}"
if [ "$use_latest" == "true" ]; then
    LOCATION=$(curl -sS https://api.github.com/repos/$gh_repo/releases/latest | jq -r '.zipball_url')
else
    LOCATION=$(curl -sS https://api.github.com/repos/$gh_repo/releases | jq -r ".[] | select(.tag_name == \"$selected_version\") | .zipball_url")
fi

if [ -z "$LOCATION" ]; then
    echo -e "${RED}Не удалось определить URL для загрузки.${RESET}"
    exit 2
fi

# Создание временной директории для установки
TEMP_DIR="$HOME/fpc-install"
mkdir -p "$TEMP_DIR"

if ! curl -L "$LOCATION" -o "$TEMP_DIR/fpc.zip" ; then
    echo -e "${RED}Ошибка при загрузке архива.${RESET}"
    exit 2
fi

if ! unzip "$TEMP_DIR/fpc.zip" -d "$TEMP_DIR" ; then
    echo -e "${RED}Ошибка при распаковке архива.${RESET}"
    exit 2
fi

if ! mv "$TEMP_DIR"/*/* "$WORK_DIR/" ; then
    echo -e "${RED}Ошибка при перемещении файлов.${RESET}"
    exit 2
fi

rm -rf "$TEMP_DIR"

# Создание виртуального окружения и установка зависимостей
echo -e "${GREEN}Создаю виртуальное окружение Python...${RESET}"
if ! python -m venv "$HOME/pyvenv" ; then
    echo -e "${RED}Ошибка при создании виртуального окружения.${RESET}"
    exit 2
fi

echo -e "${GREEN}Устанавливаю зависимости...${RESET}"
source "$HOME/pyvenv/bin/activate"

if [ -f "$WORK_DIR/requirements.txt" ]; then
    if ! pip install -U -r "$WORK_DIR/requirements.txt" ; then
        echo -e "${RED}Ошибка при установке зависимостей из requirements.txt${RESET}"
        exit 2
    fi
else
    echo -e "${YELLOW}Устанавливаю минимальный набор зависимостей...${RESET}"
    if ! pip install requests pytelegrambotapi pyyaml aiohttp requests_toolbelt lxml bcrypt beautifulsoup4 ; then
        echo -e "${RED}Ошибка при установке зависимостей.${RESET}"
        exit 2
    fi
fi

# Первичная настройка
echo -e "${GREEN}Запускаю первичную настройку...${RESET}"
if ! python "$WORK_DIR/main.py" ; then
    echo -e "${RED}Ошибка при первичной настройке FunPayCardinal.${RESET}"
    exit 2
fi

# Запуск в screen
echo -e "${GREEN}Запускаю FunPayCardinal в screen сессии...${RESET}"
screen -dmS fpc bash -c "source $HOME/pyvenv/bin/activate && python $WORK_DIR/main.py"

echo -e "${CYAN}################################################################################${RESET}"
echo -e "${CYAN}!СДЕЛАЙ СКРИНШОТ!!СДЕЛАЙ СКРИНШОТ!!СДЕЛАЙ СКРИНШОТ!!СДЕЛАЙ СКРИНШОТ!${RESET}"
echo ""
echo -e "${CYAN}Готово!${RESET}"
echo -e "${CYAN}FPC запущен в screen сессии 'fpc'${RESET}"
echo -e "${CYAN}Для подключения к сессии используй команду: screen -r fpc${RESET}"
echo -e "${CYAN}Для отсоединения от сессии нажми Ctrl+A D${RESET}"
echo -e "${CYAN}Для списка сессий используй: screen -ls${RESET}"
echo -e "${CYAN}Теперь напиши своему Telegram-боту.${RESET}"
echo -e "${CYAN}################################################################################${RESET}"
echo -n -e "${CYAN}Сделал скриншот? Тогда нажми Enter, чтобы продолжить.${RESET}"
read 
