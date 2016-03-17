#!/bin/bash

## https://unix.stackexchange.com/questions/226872/how-to-shrink-root-filesystem-without-booting-a-livecd/227318#227318

usage() {
    echo "$0 <device> <device_partition> <size>"
    echo "$0 /dev/mmcblk0 /dev/mmcblk0p2 1G"
}

if [ $# -ne 3 ]; then
    usage
    exit -1
fi

device="$1"
device_partition="$2"
size="$3"

umount -a
mount | column -t
mv /etc/apt/sources.d/* ~
apt-get -y install psmisc

mkdir /tmp/tmproot
mount -t tmpfs none /tmp/tmproot
mkdir /tmp/tmproot/{proc,sys,dev,run,usr,var,tmp,oldroot}
cp -ax /{bin,etc,mnt,sbin,lib,lib64} /tmp/tmproot/
cp -ax /usr/{bin,sbin,lib,lib64} /tmp/tmproot/usr/
cp -ax /var/{account,empty,lib,local,lock,nis,opt,preserve,run,spool,tmp,yp} /tmp/tmproot/var/


mount --make-rprivate /
pivot_root /tmp/tmproot /tmp/tmproot/oldroot
for i in dev proc sys run; do mount --move /oldroot/$i /$i; done

systemctl restart sshd
systemctl status sshd
fuser -vm /oldroot
kill -9  $(fuser -vm /oldroot | awk "{print $3}")
systemctl daemon-reexec

resize2fs $device_partition $size

umount /oldroot

mount $device_partition /oldroot
mount --make-rprivate /
pivot_root /oldroot /oldroot/tmp/tmproot
for i in dev proc sys run; do mount --move /tmp/tmproot/$i /$i; done


systemctl restart sshd
systemctl status sshd
fuser -vm /tmp/tmproot
kill -9  $(fuser -vm /tmp/tmproot | awk "{print $3}")
systemctl daemon-reexec


umount /tmp/tmproot
rmdir /tmp/tmproot

mount -a

systemctl | grep failed | awk "{print $1}"| while read i; do systemctl restart "$i"; done;
mount --make-rshared /


## TODO: add fisk commands here
## echo -e "d\n2\nn\n2\n\n1G\nw" | fdisk $device  ## this needs to be verified, writing down from memory