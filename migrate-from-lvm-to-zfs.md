### Исходные данные
Есть /dev/sda (gpt), на нем разделы: esp (/dev/sda1), boot (/dev/sda2) и lvm с debian (/dev/sda3)  
Есть пустой /dev/sdb  
Нужно перенести систему на zfs mirror, получив структуру:
/dev/sd*1 - esp (fat32 с одним файлом /boot/bootx64.efi)
/dev/sd*2 - zfs mirror "rootfs"  
swap перенести в файл /swap

[sudo -i][#sudo -i]  
[Перенести swap][]  

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

### Подключить репозитории  
```
добавить contrib
apt update
```

### Установить необходимые пакеты  
```
apt install -y dosfstools linux-headers-$(uname -r) zfsutils-linux zfs-initramfs grub-efi-amd64
```
Если для сборки initrd планируется использовать dracut:  
```
apt install -y dracut zfs-dracut
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

### Установить grub или refind  
  - добавить нужные модули (lvm, mdadm, zfs)  
  - установить  
  - сделать конфиг при необходимости  
### Перенос системы
  - Скопировать root, boot (и прочее, если есть)  
  - Зачистить синформацию о старых томах в настройках initram, прописать при необходимости новые  
  - Сгенерить initramfs (с помощью initramfs или drakut, тоже с модулями lvm, mdadm, zfs)  
  - Поправить fstab  
  - Добавить загрузочную запись в grub/refind, проверить работу  
