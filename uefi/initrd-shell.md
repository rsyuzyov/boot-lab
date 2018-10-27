shell = busybox => имеем неплохое башеподобное окружение, можно много чем пользоваться  
https://wiki.debian.org/InitramfsDebug  

cat /proc/modules
cat /proc/cmdline
modprobe zfs

lsinitramfs /boot/initrd
