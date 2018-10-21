fdisk - голимая консоль  
cfdisk - почти гуи  
sfdisk - разметка  
  
аналоги (типа для gpt, но по факту и и msdod умеют)  
gdisk  
cgdisk  
sgdisk - конвертация mbr->gpt  обратно, hybrydmbr и прочая пакость  
  
grub-install /dev/sdb
update-grub /dev/sdb
grub-mkconfig -o /boot/grub/grub/conf
dpkg-reconfigure grub-pc

refind-install /dev/sdb
update-refind /dev/sdb
dpkg-reconfigure refind

https://www.supergrubdisk.org/ 
