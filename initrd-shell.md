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
modprobe zfs
zpool import -R /root rpool
exec switch_root /root /sbin/init
exec switch_root /root /sbin/init
```
После загрузки:
```
echo " rootdelay=3 root=ZFS=rpool/ROOT/pve-1 boot=zfs" > /etc/kernel/cmdline
proxmox-boot-tool refresh
```
Заодно можно отключить патчи от SPECTRE, существенно замедляющие работу ядра, в этом случае строка будет немного длинней:
```
echo " rootdelay=3 root=ZFS=rpool/ROOT/pve-1 boot=zfs noibrs noibpb nopti nospectre_v2 nospectre_v1 l1tf=off nospec_store_bypass_disable no_stf_barrier mds=off tsx=on tsx_async_abort=off mitigations=off" > /etc/kernel/cmdline 
proxmox-boot-tool refresh
```
