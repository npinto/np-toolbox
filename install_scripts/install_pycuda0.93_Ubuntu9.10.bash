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
echo -e "[${RED} Preliminary tests ${NC}]"
source /etc/zsh/zshenv
nvcc --version || exit 1

# ------------------------------------------------------------------------------
NPROCS=$(grep processor /proc/cpuinfo | wc -l)

TMP_DIR=$(mktemp -d)
cd $TMP_DIR

# ------------------------------------------------------------------------------
echo -e "[${RED} Installing dependencies ${NC}]"
apt-get install python-dev libboost-python1.38-dev -y

# ------------------------------------------------------------------------------
echo -e "[${RED} Downloading source code ${NC}]"
wget "http://pypi.python.org/packages/source/p/pycuda/pycuda-0.93.tar.gz"
tar xzf pycuda-0.93.tar.gz
cd pycuda-0.93

# ------------------------------------------------------------------------------
echo -e "[${RED} Configuring ${NC}]"
./configure.py \
--cuda-root=/usr/local/cuda \
--cudadrv-lib-dir=/usr/lib/ \
--boost-inc-dir=/usr/include/ \
--boost-lib-dir=/usr/lib/ \
--boost-python-libname=boost_python-mt \
--boost-thread-libname=boost_thread-mt 

# ------------------------------------------------------------------------------
echo -e "[${RED} Building ${NC}]"
make -j $NPROCS

# ------------------------------------------------------------------------------
echo -e "[${RED} Installing ${NC}]"
python setup.py install


# ------------------------------------------------------------------------------
echo -e "[${RED} Testing ${NC}]"
TEST_DRIVER=test/test_driver.py
if [ $(python ${TEST_DRIVER}) ]; then
echo "Error: $TEST_DRIVER failed!"; 
exit 1;
fi;

# ------------------------------------------------------------------------------
echo -e "[${RED} Cleaning up ${NC}]"
rm -rf $TMP_DIR

# ------------------------------------------------------------------------------
echo "Installation successful!"

