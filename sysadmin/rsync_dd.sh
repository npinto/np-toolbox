#!/bin/bash

PROGNAME=$(basename $0)
function error_exit
{
    echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
    exit 1
}

if [[ $# != 2 ]]; then
    echo "Usage: $PROGNAME /dev/source /dev/destination"
fi;

#set -e
#set -x

src=$1
dst=$2

file $src | grep block || error_exit "ERROR: $src is not a block device"
file $dst | grep block || error_exit "ERROR: $dst is not a block device"

#dd if=/dev/zero of=/dev/sdb bs=512 count=1

## backup sda extended partition table
#sfdisk -d /dev/sda > sda.sfdisk

## restore it into sdb
#sfdisk /dev/sdb < sda.sfdisk

## swap
#mkswap /dev/sdb5
## root
#mkfs.ext4 /dev/sdb6

## rsync
#mkdir -p /mnt/clone
#mount /dev/sdb6 /mnt/clone
#mkdir -p /mnt/clone/{sys,proc,dev}
#rsync -avxz --exclude=/proc --exclude=/sys --exclude=/dev / /mnt/clone
#rsync -ahHAvxz --exclude=/proc/* --exclude=/sys/* --exclude=/tmp/* --exclude=/root/* /* /mnt/clone/

## monitor progress
#watch df -h /dev/sd{a,b}6

## grub w/ attached drive (i.e. sdb6 => hd1,5)

#mount -t proc none /mnt/clone/proc
#mount -o bind /dev /mnt/clone/dev
#mount -o bind /sys /mnt/clone/sys 
#chroot /mnt/clone /bin/bash

#grub
#grub> root (hd1,5)
#grub> setup (hd1)
#grub> quit
