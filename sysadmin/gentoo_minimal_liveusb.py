#!/usr/bin/env python

import os
import sys
import subprocess as sp
import shlex

def run(cmd):
    #sp.check_call(shlex.split("emerge -u sys-fs/dosfstools '>sys-boot/syslinux-3'"))
    print cmd
    assert os.system(cmd) == 0

if os.geteuid() != 0:
    print "You must be root to run this script."
    sys.exit(1)

print("=" * 80)
print("Installing dependencies...")
run("emerge -u sys-fs/dosfstools '>sys-boot/syslinux-3' sys-fs/squashfs-tools")

cat /proc/filesystems | grep squashfs


# wipe out
dd if=/dev/zero of=/dev/sdd bs=512 count=1
# partition table
echo -e 'o\nn\np\n1\n\n\nt\n6\na\n1\nw\n' | fdisk /dev/sdd
# format
mkdosfs -F 16 /dev/sdd1
# mbr
dd if=/usr/share/syslinux/mbr.bin of=/dev/sdd

# iso
wget -r --level 1 -A .iso http://distfiles.gentoo.org/releases/amd64/autobuilds/current-iso/

ISO_FNAME='install-amd64-minimal-20110707.iso'
wget http://distfiles.gentoo.org/releases/amd64/autobuilds/current-iso/${ISO_FNAME}

mkdir -p ./mnt_iso && mount -o loop,ro -t iso9660 ${ISO_FNAME} ./mnt_iso

mkdir -p ./mnt_usb && mount -t vfat /dev/sdd1 ./mnt_usb

cp -r ./mnt_iso/* ./mnt_usb

mv ./mnt_usb/isolinux/* ./mnt_usb/
mv ./mnt_usb/isolinux.cfg ./mnt_usb/syslinux.cfg
rm -rf ./mnt_usb/isolinux*

mv ./mnt_usb/memtest86 ./mnt_usb/memtest

umount ./mnt_iso

sed -i -e "s:cdroot:cdroot slowusb:" -e "s:kernel memtest86:kernel memtest:" ./mnt_usb/syslinux.cfg

mkdir -p ./squashfs && mount -o loop,ro -t squashfs ./mnt_usb/image.squashfs ./squashfs

cp -a ./squashfs{,_new}

mksquashfs ./squashfs_new ./image.squashfs

cp -vf ./image.squashfs ./mnt_usb

umount ./mnt_usb

syslinux /dev/sdd1




## -- Helpers
#PROGNAME=$(basename $0)
#function error_exit
#{
    #echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
    #exit 1
#}

## Exit immediately if error in the scrit
#set -e

## ------------------------------------------------------------------------------
## Make sure only root can run our script
#if [[ $EUID -ne 0 ]]; then
    #echo "This script must be run as root" 1>&2
    #exit 1
#fi
## ------------------------------------------------------------------------------

#test ! -n $USBDEV && error_exit "\$USBDEV must be defined"

#file $USBDEV | grep block || error_exit "'$USBDEV' is not a block device"

#test -f /usr/share/syslinux/mbr.bin


#echo "!!!!!!!!!!!!!!!!!! WARNING !!!!!!!!!!!!!!!!!!"
#echo "Device '$USBDEV' will be _wiped_ and memtest will be installed"
#echo "Are you sure you want to continue?"
#echo "Press any key to continue or Ctrl-C to stop"
#echo "!!!!!!!!!!!!!!!!!! WARNING !!!!!!!!!!!!!!!!!!"
#read

## Echo all commands
#set -x

### delete entire partition table on the usb disk
##dd if=/dev/zero of=$USBDEV bs=1M count=1

## create 1 partition
#fdisk $USBDEV << EOF
#o
#n
#p
#1


#t
#6
#a
#1
#w
#EOF

## format as fat16
#mkdosfs -F 16 ${USBDEV}1

## install mbr
#dd if=/usr/share/syslinux/mbr.bin of=$USBDEV

## mount
#export mnt=$(mktemp -d)
#mount ${USBDEV}1 $mnt

## copy memtest
#curl  http://www.memtest.org/download/4.20/memtest86+-4.20.bin.gz | zcat > $mnt/memtest

## configure syslinux
#cat > $mnt/syslinux.cfg << EOF
#default memtest86
#prompt 1
#timeout 10
#label memtest86
    #kernel memtest
#EOF

## clean up
#umount $mnt

## syslinux
#syslinux ${USBDEV}1
