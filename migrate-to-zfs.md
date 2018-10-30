### Исходные данные
Есть /dev/sda (gpt), на нем разделы: esp (/dev/sda1), boot (/dev/sda2) и lvm с debian (/dev/sda3)  
Все каталоги, в том числе home, находятся на корневом диске  
Есть пустой /dev/sdb  

Нужно не выходя из системы перенести систему на зеркало zfs, получив идентичную структуру на обоих дисков:
/dev/sd*1 - esp (fat с одним файлом /efi/boot/bootx64.efi)
/dev/sd*2 - zfs mirror "rootfs"  
swap перенести в файл /swap  

### План  
[sudo -i](#sudo--i)  
[Перенести swap](#перенести-swap)  
[Установить необходимые пакеты](#установить-необходимые-пакеты)  
[Разметить диск](разметить-диск)  
[Установить grub или refind](#установить-grub-или-refind)  
[Перенести систему](#перенести-систему)  
[Установить загрузчик](#установить-загрузчик)  

### sudo -i
```
sudo -i
```

### Перенести swap
```
dd if=/dev/zero of=/swap bs=256M count=4
chmod 644 /swap
mkswap /swap
swapon /swap
```
в fstab замеить запись подключения swap:  
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
ln -s /bin/rm /usr/bin/rm
modprobe zfs
systemctl start zfs*
```

### Разметить диск  
Создать разделы esp, boot:  
```
echo -e "label: gpt \n\
1 : start=2048, size=256M, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B" \n\
2 : size=16G, type=6A898CC3-1DD2-11B2-99A6-080020736631\
| sfdisk /dev/sdb1
```
(Можно сохранить разметку с уже существующего диска в файл, подправить и загрузить на новый диск: sfdisk -d /dev/sda >> ~/gpt.txt, затем правка и cat ~/gpt.txt | sfdisk /dev/sdb)  

Отформатировать esp в fat:  
```
mkfs.vfat /dev/sdb1
```
Создать пул (он же будет и датасетом) zfs:
```
zpool create -o ashift=12 rootfs /dev/sdb2
zfs set recordsize=4K rootfs
zfs set atime=off rootfs
zfs set compression=lz4 rootfs
zfs set sync=disabled rootfs
```

### Скопировать систему
Скопировать root и boot:
```
rsync -aAHXv /* /rootfs --exclude={/rootfs,/swap,/mnt/*,/lost+found,/proc/*,/sys/*,/dev/*,/tmp/*,/boot/efi/*}
```
Смонтировать esp в /boot/efi/:  
```
mount /dev/sdb1 /rootfs/boot/efiebianx64.efi /rootfs/boot/efi/EFI/boot/bootx64.efi
```
# Настроить новую систему
Переключить корневую ФС на новую систему:
```
mount --bind /dev /rootfs/dev
mount --bind /proc /rootfs/proc
mount --bind /sys /rootfs/sys
chroot /rootfs
```
Установить grub:
```
grub-install --no-nvram --root-directory / --boot-directory /boot --efi-directory /boot/efi
```
Скопировать файл загрузчика по дефолтному для поиска загрузчика адресу в uefi:  
```
mkdir /boot/efi/EFI/boot
cp /boot/efi/EFI/debian/debianx64.efi /boot/efi/EFI/boot/bootx64.efi
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
где XXXX-XXXX для /boot/efi - это идентификатор блочного устройства, узнать его можно с помощью команды blkid | grep /dev/sdb1  
