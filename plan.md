### Исходные данные
Есть /dev/sda (gpt), на нем разделы: esp (/dev/sda1), boot (/dev/sda2) и lvm с debian (/dev/sda3)  
Есть пустой /dev/sdb  
Нужно перенести систему на zfs mirror, получив структуру:
/dev/sd*1 - esp (fat32 с одним файлом /boot/bootx64.efi)
/dev/sd*2 - zfs mirror "rootfs"  

### Подключить репозитории  
```
добавить contrib
apt update
```

### Установить необходимые пакеты  
```
apt install -y dosfstools zfsutils-linux zfs-initramfs grub-efi-amd64
```
Если для сборки initrd планируется использовать dracut:  
```
apt install -y zfs-dracut
```

### Разметить диск  
Создать разделы esp, boot:  
```
```
Отформатировать:  
```
```
### Установить grub или refind  
  - добавить нужные модули (lvm, mdadm, zfs)  
  - установить  
  - сделать конфиг при необходимости  
Скопировать root, boot (и прочее, если есть)  
Зачистить синформацию о старых томах в настройках initram, прописать при необходимости новые  
Сгенерить initramfs (с помощью initramfs или drakut, тоже с модулями lvm, mdadm, zfs)  
Поправить fstab  
Добавить загрузочную запись в grub/refind, проверить работу  
