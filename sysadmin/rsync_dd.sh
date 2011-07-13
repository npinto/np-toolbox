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

set -e
#set -x

src=$1
dst=$2

file $src | grep block || error_exit "ERROR: $src is not a block device"
file $dst | grep block || error_exit "ERROR: $dst is not a block device"

echo "WARNING WARNING WARNING WARNING WARNING WARNING"
echo "$src will be clone into $dst, all data from $dst will be DELETED"
echo "Press any key to continue or Ctrl-C to quit"
read

echo "========================================================================="
echo "Copying partition table..."
dd if=/dev/zero of=$dst bs=1M count=1
sfdisk -d $src > $(basename $src).sfdisk
sfdisk $dst < $(basename $src).sfdisk
echo "Sleeping..."
sleep 3
echo "done."

echo "========================================================================="
devswap=$(fdisk -l $dst | grep 'Linux swap' | awk '{print $1}')
echo "Creating swap partition on '$devswap' ..."
mkswap $devswap

echo "========================================================================="
devsys=$(fdisk -l $dst | grep '83  Linux' | head -n1 | awk '{print $1}')
echo "Creating ext4 partition on '$devsys' ..."
time mkfs.ext4 $devsys

echo "========================================================================="
echo "Rsync'ing..."
mkdir -p ./mnt_tmp
mount $devsys ./mnt_tmp
mkdir -p ./mnt_tmp/{sys,proc,dev}
time rsync -ahHAx --exclude=/proc/* --exclude=/sys/* --exclude=/mnt/* --exclude=$(pwd)/* --exclude=/root/.ssh/* /* ./mnt_tmp/

echo "========================================================================="
echo "Installing grub..."
grub-install --recheck --root-directory=./mnt_tmp $dst

echo "========================================================================="
echo "Cleaning up..."
umount ./mnt_tmp && rm -rf ./mnt_tmp
rm -vf $(basename $src).sfdisk
