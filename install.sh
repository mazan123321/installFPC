#!/bin/bash

GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
CYAN='\033[36m'
RESET='\033[0m'

echo -e "${GREEN}"
echo "Установщик для Termux, создан @exfador, основан на предыдущей версии от @sidor0912${RESET}"
echo "Запуск с использованием последней версии FunPayCardinal."

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
curl -L "$LOCATION" -o /data/data/com.termux/files/home/fpc-install/fpc.zip

# Распаковка архива
echo -e "${GREEN}Распаковываю архив...${RESET}"
unzip /data/data/com.termux/files/home/fpc-install/fpc.zip -d /data/data/com.termux/files/home/fpc-install

# Создание директории для FunPayCardinal
mkdir -p /data/data/com.termux/files/home/FunPayCardinal

# Перемещение файлов в нужную директорию
mv /data/data/com.termux/files/home/fpc-install/*/* /data/data/com.termux/files/home/FunPayCardinal/

# Очистка
rm -rf /data/data/com.termux/files/home/fpc-install

# Установка зависимостей
echo -e "${GREEN}Устанавливаю зависимости...${RESET}"
pkg install -y curl unzip python jq

# Устанавливаем Python и виртуальное окружение
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
echo "python /data/data/com.termux/files/home/FunPayCardinal/main.py" >> /data/data/com.termux/files/home/fpc_start.sh
chmod +x /data/data/com.termux/files/home/fpc_start.sh

# Инструкция по использованию
echo -e "${CYAN}################################################################################${RESET}"
echo -e "${CYAN}FPC успешно установлен и настроен!${RESET}"
echo -e "${CYAN}Чтобы запустить бота, просто используйте Termux Widget, выбрав fpc_start.sh.${RESET}"
echo -e "${CYAN}################################################################################${RESET}"
