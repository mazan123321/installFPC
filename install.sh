#!/bin/bash

GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
CYAN='\033[36m'
RESET='\033[0m'

echo -e "${GREEN}"
echo "Установщик FunPayCardinal для Termux/Proot"
echo "Адаптировано для работы без root и отдельного пользователя"
echo -e "${RESET}"

# Проверяем, что мы внутри Proot-окружения
if [ -z "$PROOT_ROOT_DIR" ]; then
  echo -e "${YELLOW}Рекомендуется запускать через proot-distro:"
  echo "pkg install proot-distro"
  echo "proot-distro install ubuntu"
  echo "proot-distro login ubuntu"
  echo "После этого повторите запуск скрипта${RESET}"
  sleep 3
fi

echo -e "${GREEN}Обновляю списки пакетов...${RESET}"
apt update && apt upgrade -y

echo -e "${GREEN}Устанавливаю базовые зависимости...${RESET}"
apt install -y curl unzip screen jq python3.11 python3.11-venv git

echo -e "${GREEN}Выбираем версию FPC...${RESET}"
gh_repo="sidor0912/FunPayCardinal"
releases=$(curl -sS https://api.github.com/repos/$gh_repo/releases | grep "tag_name" | awk '{print $2}' | sed 's/"//g' | sed 's/,//g')

if [ -n "$releases" ]; then
  echo -e "${YELLOW}Доступные версии:${RESET}"
  versions=($releases)
  for i in "${!versions[@]}"; do
    echo "$i) ${versions[$i]}"
  done
  echo "latest) Последняя версия"
  
  read -p "${YELLOW}Выберите версию [latest]: ${RESET}" version_choice
  if [[ "$version_choice" == "latest" || -z "$version_choice" ]]; then
    version="latest"
  elif [[ ${versions[$version_choice]} ]]; then
    version=${versions[$version_choice]}
  else
    version="latest"
  fi
else
  version="latest"
fi

echo -e "${GREEN}Скачиваем FunPayCardinal...${RESET}"
if [ "$version" == "latest" ]; then
  git clone https://github.com/$gh_repo.git FunPayCardinal
else
  git clone --branch $version https://github.com/$gh_repo.git FunPayCardinal
fi

cd FunPayCardinal

echo -e "${GREEN}Создаем виртуальное окружение...${RESET}"
python3.11 -m venv pyvenv
source pyvenv/bin/activate

echo -e "${GREEN}Устанавливаем зависимости...${RESET}"
if [ -f requirements.txt ]; then
  pip install -U -r requirements.txt
else
  pip install psutil beautifulsoup4 colorama requests pytelegrambotapi pillow aiohttp requests_toolbelt lxml bcrypt
fi

echo -e "${GREEN}Первичная настройка...${RESET}"
python main.py

echo -e "${GREEN}Запускаем в screen...${RESET}"
screen -dmS fpc python main.py

echo -e "${CYAN}----------------------------------------------------------${RESET}"
echo -e "${GREEN}Установка завершена!${RESET}"
echo -e "Для подключения к сессии: ${CYAN}screen -r fpc${RESET}"
echo -e "Для выхода из screen: ${CYAN}Ctrl+A затем D${RESET}"
echo -e "Файлы бота находятся в: ${CYAN}$(pwd)${RESET}"
echo -e "${CYAN}----------------------------------------------------------${RESET}"
