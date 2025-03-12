#!/bin/bash

GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
CYAN='\033[36m'
RESET='\033[0m'

# Логирование
LOG_FILE="/data/data/com.termux/files/home/fpc_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo -e "${CYAN}Лог установки записывается в $LOG_FILE${RESET}"

echo -e "${GREEN}"
echo "Установщик для Termux, создан @exfador, основан на предыдущей версии от @sidor0912${RESET}"
echo "Запуск с использованием последней версии FunPayCardinal."

# Проверка зависимостей
check_dependency() {
  if ! command -v "$1" &> /dev/null; then
    echo -e "${RED}Необходимый инструмент '$1' не найден. Устанавливаю...${RESET}"
    pkg install -y "$1"
  fi
}

check_dependency curl
check_dependency jq
check_dependency unzip

# Создание директории для установки
username="termuxuser"

echo -e "${GREEN}Создаю директорию для установки...${RESET}"
mkdir -p /data/data/com.termux/files/home/fpc-install

gh_repo="sidor0912/FunPayCardinal"

# Получаем ссылку на последнюю версию
LOCATION=$(curl -sS https://api.github.com/repos/$gh_repo/releases/latest | jq -r '.zipball_url')

if [ -z "$LOCATION" ]; then
  echo -e "${RED}Не удалось определить URL для загрузки.${RESET}"
  exit 2
fi

# Загрузка архива
echo -e "${GREEN}Загружаю последнюю версию FunPayCardinal...${RESET}"
if ! curl -L "$LOCATION" -o /data/data/com.termux/files/home/fpc-install/fpc.zip; then
  echo -e "${RED}Ошибка при загрузке архива. Проверьте подключение к интернету.${RESET}"
  exit 1
fi

# Распаковка архива
echo -e "${GREEN}Распаковываю архив...${RESET}"
unzip /data/data/com.termux/files/home/fpc-install/fpc.zip -d /data/data/com.termux/files/home/fpc-install

# Создание директории для FunPayCardinal
mkdir -p /data/data/com.termux/files/home/FunPayCardinal

# Перемещение файлов в нужную директорию
mv /data/data/com.termux/files/home/fpc-install/*/* /data/data/com.termux/files/home/FunPayCardinal/

# Очистка
rm -rf /data/data/com.termux/files/home/fpc-install
rm -f /data/data/com.termux/files/home/fpc-install/fpc.zip

# Установка зависимостей
echo -e "${GREEN}Устанавливаю зависимости...${RESET}"
pkg install -y curl unzip python jq


# Проверка версии Python
PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
if (( $(echo "$PYTHON_VERSION < 3.8" | bc -l) )); then
  echo -e "${RED}Требуется Python 3.8 или выше. Установите новую версию Python.${RESET}"
  exit 1
else
  echo -e "${GREEN}Обнаружена подходящая версия Python: $PYTHON_VERSION${RESET}"
fi

echo -e "${GREEN}Устанавливаю Python и создаю виртуальное окружение...${RESET}"
pkg install -y python
python3 -m venv /data/data/com.termux/files/home/pyvenv
source /data/data/com.termux/files/home/pyvenv/bin/activate
pip install --upgrade pip

# Устанавливаем зависимости для FunPayCardinal
echo -e "${GREEN}Устанавливаю зависимости для FunPayCardinal...${RESET}"
pip install -r /data/data/com.termux/files/home/FunPayCardinal/requirements.txt

# Скрипт для автозапуска через Termux Widget
echo -e "${GREEN}Создаю скрипт автозапуска для Termux Widget...${RESET}"
echo '#!/data/data/com.termux/files/usr/bin/bash' > /data/data/com.termux/files/home/fpc_start.sh
echo "source /data/data/com.termux/files/home/pyvenv/bin/activate" >> /data/data/com.termux/files/home/fpc_start.sh
echo "python /data/data/com.termux/files/home/FunPayCardinal/main.py > /data/data/com.termux/files/home/fpc.log 2>&1" >> /data/data/com.termux/files/home/fpc_start.sh
chmod +x /data/data/com.termux/files/home/fpc_start.sh

# Инструкция по использованию
echo -e "${CYAN}################################################################################${RESET}"
echo -e "${CYAN}FPC успешно установлен и настроен!${RESET}"
echo -e "${CYAN}Чтобы запустить бота:${RESET}"
echo -e "${CYAN}1. Откройте Termux Widget."
echo -e "${CYAN}2. Выберите скрипт 'fpc_start.sh'."
echo -e "${CYAN}Логи работы бота будут сохранены в файле 'fpc.log'.${RESET}"
echo -e "${CYAN}################################################################################${RESET}"
