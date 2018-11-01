### Исходные данные
Есть /dev/sda (gpt), на нем разделы: esp (/dev/sda1), boot (/dev/sda2) и lvm (/dev/sda3)  
ОС: debian stretch, ядро 4.9.0.7 - учитываем это при копипасте команд :).  
Все каталоги, в том числе home, находятся на корневом диске  
Есть пустой /dev/sdb  

Нужно не выходя из системы перенести систему на зеркало zfs, получив идентичную структуру на обоих дисков:
/dev/sd*1 - esp (fat с одним файлом /efi/boot/bootx64.efi)
/dev/sd*2 - zfs mirror "rootfs"  
/boot расположить в корневом разделе (не выносить на отдельный раздел)
swap перенести в файл /swap  

### План  
[sudo -i](#подготовка)  
[Перенести swap](#перенести-swap)  
[Установить необходимые пакеты](#установить-необходимые-пакеты)  
[Разметить диск](#разметить-диск)  
[Установить grub или refind](#установить-grub)  
[Перенести систему](#скопировать-систему)  
[Установить загрузчик](#настроить-новую-систему)  

### Подготовка
```
sudo -i
```
Прежде всего нужно проверить наличие uefi:  
Можно проверить существование каталога /sys/firmware/efi либо воспользоваться утилитой efibootmgr:  
```
apt install efibootmgr
efibootmgr
```

### Перенести swap
```
dd if=/dev/zero of=/swap bs=256M count=4
mkswap /swap
chmod 600 /swap
swapon /swap
```
Заменить запись подключения swap в fstab:  
```
/swap none swap sw 0 0
```

### Установить необходимые пакеты  
В первую очередь для основного репозитория подключить набор пакетов (компоненту) contrib - zfs обитает там в виду невозможности включения в main из-за лицензионной несовместимости  
```
apt update
apt install -y rsync dosfstools linux-headers-$(uname -r) zfsutils-linux zfs-initramfs grub-efi-amd64
```
Запустить zfs:  
```
ln -s /bin/ьлштшrm /usr/bin/rm
modprobe zfs
systemctl start zfs*
```

### Разметить диск  
Создать разделы esp, boot:  
```
sfdisk /dev/sdb << EOF
label: gpt
1 : start=2048, size=256M, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
2 : start=526336, size=16G, type=6A898CC3-1DD2-11B2-99A6-080020736631
EOF
```
(Можно сохранить разметку с уже существующего диска в файл, подправить и загрузить на новый диск: sfdisk -d /dev/sda >> ~/gpt.txt, затем правка и cat ~/gpt.txt | sfdisk /dev/sdb)  

Отформатировать esp в fat:  
```
mkfs.vfat /dev/sdb1
```
Создать пул (он же будет и датасетом) zfs:
```
zpool create -o ashift=12 rootfs /dev/sdb2
zpool set bootfs=rootfs rootfs
zfs set recordsize=4K rootfs
zfs set atime=off rootfs
zfs set compression=lz4 rootfs
zfs set sync=disabled rootfs
```

### Скопировать систему
Скопировать root, смонтировать esp в /boot/efi/:  
```
rsync -aAHXv /* /rootfs --exclude={/rootfs,/swap,/mnt/*,/lost+found,/proc/*,/sys/*,/dev/*,/tmp/*,/boot/efi/*}
mount /dev/sdb1 /rootfs/boot/efi
```
# Настроить новую систему
Переключить корневую ФС на новую систему:
```
mount --rbind /dev /rootfs/dev
mount --rbind /proc /rootfs/proc
mount --rbind /sys /rootfs/sys
chroot /rootfs
```
Установить grub:
```
grub-install --no-nvram --root-directory / --boot-directory /boot --efi-directory /boot/efi
```
Скопировать файл загрузчика по дефолтному для поиска загрузчика адресу в uefi:  
```
mkdir /boot/efi/EFI/boot
cp /boot/efi/EFI/debian/grubx64.efi /boot/efi/EFI/boot/bootx64.efi
```
Зачистить синформацию о томах lvm в конфигах initramfs:  
```
nano /etc/initramfs-tools/conf.d/resume
```
В нашем случае будет запись типа `RESUME=/dev/mapper/...`, нужно удалить ее.  

Пересобрать initramfs:  
```
update-initramfs -u -k all
```
Поправить fstab. Приводим к виду:  
```
/dev/disk/by-label/rootfs /              zfs           errors=remount-ro 0 1
UUID=XXXX-XXXX            /boot/efi      vfat          umask=0077        0 1
/swap                     none           swap          sw                0 0
/dev/sr0                  /media/cdrom0  udf,iso9660   usr,noauto        0 0
```
где XXXX-XXXX для /boot/efi - это идентификатор блочного устройства, узнать его можно с помощью команды `blkid | grep /dev/sdb1`  
Создать /swap, так как его не копировали:  
```
dd if=/dev/zero of=/swap bs=256M count=4
mkswap /swap
chmod 600 /swap
```
Выходим из chroot:
```
exit
```
Теперь необходимо сменить точку монтирования для rootfs на /root:
```
zfs set canmount=noauto rootfs
zfs set mountpoint=/ rootfs

```
Если при выполнении будут ошибки, связанные с невозможностью размонртирования, необходимо перезагрузиться и повторить выполнение.  

### Подготовка к слепой перезагрузке
Если есть возможность зайти в uefi и указать новый диск в качестве загрузочного, то можно это сделать и пропустить этот раздел.
Иначе загрузка будет загружаться старая система.  
Чтобы загрузилась новая система, нужно в существующий конфиг grub добавить загрузочную запись для новой системы и установить ее по-умолчанию.  
Добавим вручную:
```
nano /boot/grub/grub.cfg
```
Конфиг состоит из нескольких разделов за номерами "00_...", "05_...", "10_..." и т.д.  
Нас интересует раздел `### BEGIN /etc/grub.d/10_linux`. Раздел обычно состоит из одного или нескольких блоков "menuentry" и "submenu".  
Перед первым блоком "menuentry" вставить:  
```
set default=0
set timeout=3
menuentry "*** new os ***" {
  insmod part_gpt
  insmod zfs
  linux /vmlinuz-4.9.0-7-amd64 root=ZFS=rootfs quiet
  initrd /initrd.img-4.9.0-7-amd64
}
```
Не забываем указать изменить имена файлов ядра и initrd на реальные!  
Осталось подложить файл загрузчика по дефолтному для поиска из uefi адресу:  
```
mkdir /boot/efi/EFI/boot
cp /boot/efi/EFI/debian/grubx64.efi /boot/efi/EFI/boot/bootx64.efi
```

================  
Если при перезагрузке открывется UEFI Interactive Shell:
Для начала смотрим краткие обзначания дисков:
```
map
```
Как правило для блочных устройств это "blkX", где Х - номер устройства
Затем перебираем диски, пока не найдем загрузочный. Методика: 
пишем blk0: и нажимаем tab. Если это раздел esp, то сработает автокомплит и появится строка "EFI". Ставим "\" (это fat!) и повторяем tab. Когда получим файл типа bootx64.efi или grubx64.efi, останется нажать enter для старта загрузчика.

================  

grub-install --..  


### Переразбивка sda, создание зеркала
```
sfdisk -f /dev/sda << EOF
label: gpt
1 : start=2048, size=256M, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
2 : start=526336, size=16G, type=6A898CC3-1DD2-11B2-99A6-080020736631
EOF
```
