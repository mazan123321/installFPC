#!/data/data/com.termux/files/usr/bin/bash

set -eo pipefail
trap "echo -e '${RED}Ошибка в строке $LINENO!${RESET}' >&2" ERR

GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
CYAN='\033[36m'
RESET='\033[0m'

echo -e "${GREEN}"
echo "FunPayCardinal для Termux"
echo "Оптимизированная версия от @mazanО1"
echo -e "${RESET}"

# Проверка существующей установки
if [ -d "$HOME/FunPayCardinal" ]; then
    read -p "${YELLOW}Директория FunPayCardinal уже существует. Перезаписать? [y/N]: ${RESET}" choice
    if [[ ! "$choice" =~ ^[Yy] ]]; then
        echo -e "${RED}Отмена установки!${RESET}"
        exit 0
    fi
    rm -rf "$HOME/FunPayCardinal"
fi

# Обновление пакетов
echo -e "${GREEN}Обновление пакетов Termux...${RESET}"
pkg update -y && pkg upgrade -y

# Проверка интернета
if ! ping -c 1 github.com &>/dev/null; then
    echo -e "${RED}Нет интернет-соединения!${RESET}"
    exit 1
fi

# Установка зависимостей
echo -e "${GREEN}Установка пакетов...${RESET}"
pkg install -y python libxml2 libxslt openssl screen curl unzip jq

# Виртуальное окружение
echo -e "${GREEN}Создание виртуального окружения...${RESET}"
python -m venv "$HOME/pyvenv" || {
    echo -e "${RED}Ошибка создания виртуального окружения!${RESET}"
    exit 1
}
source "$HOME/pyvenv/bin/activate"

# Обновление pip
echo -e "${GREEN}Обновление pip...${RESET}"
python -m pip install --upgrade pip

# Выбор версии
echo -e "${GREEN}Получение версий...${RESET}"
gh_repo="sidor0912/FunPayCardinal"
releases=$(curl -sS --fail https://api.github.com/repos/$gh_repo/releases | grep "tag_name" | awk '{print $2}' | sed 's/"//g' | sed 's/,//g')

if [ -n "$releases" ]; then
  echo -e "${YELLOW}Доступные версии:${RESET}"
  mapfile -t versions <<< "$releases"
  for i in "${!versions[@]}"; do
    echo "$i) ${versions[$i]}"
  done
  
  while true; do
    read -p "${YELLOW}Выберите версию (номер или 'latest'): ${RESET}" version_choice
    if [[ "$version_choice" == "latest" || -z "$version_choice" ]]; then
      LOCATION=$(curl -sS --fail https://api.github.com/repos/$gh_repo/releases/latest | jq -r '.zipball_url')
      break
    elif [[ "$version_choice" =~ ^[0-9]+$ ]] && [ "$version_choice" -lt "${#versions[@]}" ]; then
      LOCATION="https://github.com/$gh_repo/archive/refs/tags/${versions[$version_choice]}.zip"
      break
    else
      echo -e "${RED}Неверный выбор!${RESET}"
    fi
  done
else
  echo -e "${RED}Не удалось получить версии, использую develop ветку${RESET}"
  LOCATION="https://github.com/$gh_repo/archive/refs/heads/develop.zip"
fi

# Скачивание и распаковка
echo -e "${GREEN}Загрузка FunPayCardinal...${RESET}"
curl -L --fail "$LOCATION" -o "$HOME/fpc.zip" || {
    echo -e "${RED}Ошибка загрузки!${RESET}"
    exit 1
}

unzip -qo "$HOME/fpc.zip" -d "$HOME/fpc-tmp" || {
    echo -e "${RED}Ошибка распаковки!${RESET}"
    exit 1
}

# Проверяем структуру архива
if [ -d "$HOME/fpc-tmp/FunPayCardinal-main" ]; then
    # Перемещаем файлы из папки FunPayCardinal-main
    mv "$HOME/fpc-tmp/FunPayCardinal-main"/* "$HOME/FunPayCardinal" 2>/dev/null || {
        echo -e "${RED}Ошибка при перемещении файлов!${RESET}"
        exit 1
    }
else
    echo -e "${RED}Неверная структура архива: папка FunPayCardinal-main не найдена!${RESET}"
    exit 1
fi

# Установка зависимостей
echo -e "${GREEN}Установка Python-зависимостей...${RESET}"
REQ_FILE="$HOME/FunPayCardinal/requirements.txt"

if [ -f "$REQ_FILE" ]; then
  pip install -U -r "$REQ_FILE"
else
  echo -e "${YELLOW}requirements.txt не найден, устанавливаю базовые зависимости...${RESET}"
  pip install -U requests pytelegrambotapi pyyaml aiohttp requests_toolbelt lxml bcrypt beautifulsoup4
fi

# Первоначальная настройка
echo -e "${GREEN}Первичная настройка...${RESET}"
LANG=en_US.UTF-8 python "$HOME/FunPayCardinal/main.py"

# Создание ярлыка Termux Widget
echo -e "${GREEN}Создание ярлыка автозапуска...${RESET}"
SHORTCUTS_DIR="$HOME/.shortcuts"
mkdir -p "$SHORTCUTS_DIR"

# Создаем скрипт запуска
cat <<EOF > "$SHORTCUTS_DIR/start_fpc.sh"
#!/data/data/com.termux/files/usr/bin/bash
if screen -list | grep -q 'fpc'; then
    screen -dr fpc
else
    screen -dmS fpc bash -c "LANG=en_US.UTF-8 python $HOME/FunPayCardinal/main.py"
    screen -r fpc
fi
EOF

# Устанавливаем права на выполнение
chmod +x "$SHORTCUTS_DIR/start_fpc.sh"

# Создаем метаданные для виджета
cat <<EOF > "$SHORTCUTS_DIR/start_fpc.json"
{
  "name": "FunPayCardinal",
  "description": "Запуск/переподключение к боту",
  "icon": "play-circle",
  "categories": ["productivity"]
}
EOF

# Запуск в screen
echo -e "${GREEN}Запуск приложения...${RESET}"
if ! screen -list | grep -q "fpc"; then
    screen -dmS fpc bash -c "LANG=en_US.UTF-8 python $HOME/FunPayCardinal/main.py"
else
    echo -e "${YELLOW}Сессия fpc уже запущена!${RESET}"
fi

# Очистка
echo -e "${GREEN}Очистка...${RESET}"
rm -rf "$HOME/fpc-tmp" "$HOME/fpc.zip" "$HOME/.cache/pip"

echo -e "${CYAN}################################################################################${RESET}"
echo -e "${CYAN}Установка завершена!${RESET}"
echo -e "${CYAN}Для управления сессией:${RESET}"
echo -e "Запустить:  ${CYAN}screen -r fpc${RESET}"
echo -e "Остановить: ${CYAN}Ctrl+A D${RESET}"
echo -e "Список:     ${CYAN}screen -ls${RESET}"
echo -e "${CYAN}Не забудьте настроить config.yml!${RESET}"
echo -e ""
echo -e "${CYAN}Добавлен ярлык Termux Widget!${RESET}"
echo -e "1. Установите Termux:Widget из F-Droid"
echo -e "2. Добавьте виджет на главный экран"
echo -e "3. Выберите 'FunPayCardinal' в списке виджетов"
echo -e "${CYAN}################################################################################${RESET}"
