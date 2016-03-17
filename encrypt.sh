#!/bin/bash

## auto setup luks encryption on volume
## reference: https://trick77.com/how-to-encrypt-odroid-c1-ubuntu-root-filesystem-dm-crypt-luks/

apt-get -y install lvm2 cryptsetup parted rsync

## figure out one line command for parted or use fdisk
### parted /dev/mmcblk0
### (parted) mkpart primary ext4
### Start? 4295MB
### END? 100%
### q

echo "t\n3\n8e\nw" | fdisk /dev/mmcblk0


cryptsetup -c aes-xts-plain -y -s 512 luksFormat /dev/mmcblk0p3 ## figure out how to give passphrase
cryptsetup luksOpen /dev/mmcblk0p3 lvm ## figure out how to give passphrase
pvcreate /dev/mapper/lvm
vgcreate vg /dev/mapper/lvm
lvcreate -l 100%FREE -n root vg
mkfs.ext4 /dev/mapper/vg-root

mount /dev/mapper/vg-root /mnt

rsync -av --exclude=/media --exclude=/mnt --exclude=/proc --exclude=/dev --exclude=/sys / /mnt

mkdir -p /mnt/dev
mkdir -p /mnt/mnt
mkdir -p /mnt/proc
mkdir -p /mnt/sys
mkdir -p /mnt/media
cryptsetup luksOpen /dev/mmcblk0p3 lvm
mount /dev/mapper/vg-root /mnt
mount -o rbind /dev /mnt/dev
mount -t proc proc /mnt/proc
mount -t sysfs sys /mnt/sys
mount -t vfat /dev/mmcblk0p1 /mnt/media
chroot /mnt

echo lvm UUID=$(cryptsetup luksUUID /dev/mmcblk0p3) none luks|tee /etc/crypttab

echo "/dev/mapper/vg-root / ext4 errors=remount-ro 0 1" >> /etc/fstab

update-initramfs -u -k $(uname -r)

## check, not really relevant in automation unless verified
lsinitramfs /boot/initrd.img-$(uname -r) | grep crypt

mkimage -A arm -O linux -T ramdisk -C none -a 0 -e 0 -n "uInitrd $(uname -r)" -d /boot/initrd.img-$(uname -r) /tmp/uInitrd-$(uname -r)
cp /tmp/uInitrd-$(uname -r) /boot
cp /tmp/uInitrd-$(uname -r) /media/uInitrd


## regex inline file replace
### # Boot Arguments
### setenv bootargs "root=/dev/mapper/vg-root cryptdevice=/dev/mmcblk0p3:lvm ..."

shutdown -r now ## is this windows?
reboot