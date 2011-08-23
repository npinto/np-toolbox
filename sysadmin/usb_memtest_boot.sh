#!/bin/bash

# Dependencies, on Gentoo:
# emerge -av sys-fs/dosfstools
# emerge -av '>sys-boot/syslinux-3'


# -- Helpers
PROGNAME=$(basename $0)
function error_exit
{
    echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
    exit 1
}

# Exit immediately if error in the scrit
set -e

# ------------------------------------------------------------------------------
# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi
# ------------------------------------------------------------------------------

test ! -n $USBDEV && error_exit "\$USBDEV must be defined"

file $USBDEV | grep block || error_exit "'$USBDEV' is not a block device"

test -f /usr/share/syslinux/mbr.bin


echo "!!!!!!!!!!!!!!!!!! WARNING !!!!!!!!!!!!!!!!!!"
echo "Device '$USBDEV' will be _wiped_ and memtest will be installed"
echo "Are you sure you want to continue?"
echo "Press any key to continue or Ctrl-C to stop"
echo "!!!!!!!!!!!!!!!!!! WARNING !!!!!!!!!!!!!!!!!!"
read

# Echo all commands
set -x

## delete entire partition table on the usb disk
dd if=/dev/zero of=$USBDEV bs=512 count=1

# create 1 partition
fdisk $USBDEV << EOF
o
n
p
1


t
6
a
1
w
EOF

# format as fat16
mkdosfs -F 16 ${USBDEV}1

# install mbr
dd if=/usr/share/syslinux/mbr.bin of=$USBDEV

# mount
export mnt=$(mktemp -d)
mount ${USBDEV}1 $mnt

# copy memtest
curl  http://www.memtest.org/download/4.20/memtest86+-4.20.bin.gz | zcat > $mnt/memtest

# configure syslinux
cat > $mnt/syslinux.cfg << EOF
default memtest86
prompt 1
timeout 10
label memtest86
    kernel memtest
EOF

# clean up
umount $mnt

# syslinux
syslinux ${USBDEV}1
