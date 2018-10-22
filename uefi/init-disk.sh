#!/bin/bash

#Вызов скрипта: init-disk /dev/sdX, где /dev/sdX - целевой диск
show_help() {
cat << EOF
Usage: init-disk /dev/sdX [refind|grub]
EOF
}

if [[ ! $1 || ! $2 ]];  then
    show_help
    exit 0
fi

vol=$1
esp=${1}1
loader=$2

#На всякий случай попытаемся отмонтировать esp и удалить временные каталоги
umount ${1}1
rmdir .${1}1
rmdir ./dev

#Очистка диска
dd if=/dev/zero of=$vol bs=10M count=1

#Разметка диска: gpt, раздел ESP {тип - FAT) для размещения загрузчика
echo -e "label: gpt \n\
1 : start=2048, size=256M, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B"\
| sfdisk $vol

#Форматирование  в FAT
mkfs.vfat $esp

#Создание каталога для монтирования раздела
mkdir ./dev
mkdir .$esp
mount $esp .$esp

#Копирование загрузчика на esp
rm -rf .esp/*
mkdir .$esp/efi
mkdir .$esp/efi/boot

if [[ $loader == "refind" ]]; then
    cp -r ./templates/refind/* .$esp/efi/boot/
elif [[ $loader == "grub" ]]; then
	cp -r ./templates/grub/* .$esp/efi/boot/
	mkdir .$esp/grub
	cp -r ./templates/grub/* .$esp/grub/
else
	echo "Unknown loader: $loader!"
	exit 1
fi

#Размонтирование, удаление временных каталогов
umount ${1}1
rmdir .${1}1
rmdir ./dev

echo "$loader installed on $esp, done!"