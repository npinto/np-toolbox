#!/bin/bash

red='\e[0;31m'
RED='\e[1;31m'
blue='\e[0;34m'
BLUE='\e[1;34m'
cyan='\e[0;36m'
CYAN='\e[1;36m'
NC='\e[0m' # No Color

# ------------------------------------------------------------------------------
# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# ------------------------------------------------------------------------------
NPROCS=$(grep processor /proc/cpuinfo | wc -l)

# ------------------------------------------------------------------------------
TMP_DIR=$(mktemp -d)
cd $TMP_DIR

# ------------------------------------------------------------------------------
echo -e "[${RED} Removing previous installation (if needed) ${NC}]"
apt-get remove tmux -y

# ------------------------------------------------------------------------------
echo -e "[${RED} Installing dependencies ${NC}]"
apt-get build-dep tmux -y
apt-get install libncurses5-dev -y

# ------------------------------------------------------------------------------
echo -e "[${RED} Installing ${NC}]"
wget http://downloads.sourceforge.net/project/tmux/tmux/tmux-1.1/tmux-1.1.tar.gz
tar xzf tmux-1.1.tar.gz
cd tmux-1.1 
./configure --prefix=/usr
make -j $NPROCS
make install

# ------------------------------------------------------------------------------
echo -e "[${RED} Pseudo-testing ${NC}]"
WHICH=$(which tmux)
[[ $WHICH == '/usr/local/bin/tmux' ]] || exit 1

# ------------------------------------------------------------------------------
echo -e "[${RED} Cleaning up ${NC}]"
rm -rf $TMP_DIR

# ------------------------------------------------------------------------------
echo "Installation successful!"

