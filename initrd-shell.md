shell = busybox => имеем богатое окружение, можно много чем пользоваться  
https://wiki.debian.org/InitramfsDebug  
```
cat /proc/modules
cat /proc/cmdline
modprobe zfs
```

Просмотр содержимого образа:  
```
lsinitramfs /boot/initrd
```


Не примонтировался root на zfs:  
```
modprode zfs
import -R /root rpool
exec switch_root /root /sbin/init
exec switch_root /root /sbin/init
```
После загрузки:
```
echo " rootdelay=3 root=ZFS=rpool/ROOT/pve-1 boot=zfs" > /etc/kernel/cmdline
pve-efiboot-tool refresh
```
