#!/bin/bash

## https://unix.stackexchange.com/questions/226872/how-to-shrink-root-filesystem-without-booting-a-livecd/227318#227318

umount -a
mount | column -t
mv /etc/apt/sources.d/* ~
apt-get -y install  psmisc

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

systemctl | grep running

umount /oldroot
