#!/bin/bash

#Вызов скрипта: init-disk /dev/sdX, где /dev/sdX - целевой диск

if [ ! $0 ]; then
    echo "usage: init-disk /dev/sdX"
    exit 1
fi

#На время отладки: отключение ранее созданного раздела
umount ${1}1
rmdir .${1}1
rmdir ./dev


#Очистка диска
dd if=/dev/zero of=$1 bs=10M count=1

#Разметка диска: gpt, раздел ESP {тип - FAT) для размещения загрузчика
echo -e "label: gpt \n\
1 : start=2048, size=256M, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B"\
| sfdisk $1

#Форматирование  в FAT
mkfs.vfat ${1}1

#Создание каталога для монтирования раздела
mkdir ./dev
mkdir .${1}1
mount ${1}1 .${1}1

#Копирование загрузчика на esp
mkdir .${1}1/efi
mkdir .${1}1/efi/boot

cp -r ./templates/refind/* .${1}1/efi/boot/

echo Done!