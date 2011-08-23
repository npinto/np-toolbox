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
echo -e "[ ${RED} Initialization ${NC} ]"
if test -z ${TMP_DIR}; 
then TMP_DIR=$(mktemp -d); 
else mkdir -p ${TMP_DIR};
fi;
echo Using TMP_DIR=${TMP_DIR}

NPROCS=$(grep processor /proc/cpuinfo | wc -l)
echo Using NPROCS=${NPROCS}

# try to get the max cpu freq
for i in `seq ${NPROCS}`; 
do dd if=/dev/urandom of=/dev/null & 
done;
sleep 2
CPUFREQ=$(grep MHz /proc/cpuinfo | head -n 1 | awk '{print $4}')
kill -9 \
    $(ps aux | grep "dd if.*/dev/urandom of.*/dev/null" | \
    awk '{print $2}') 
echo Using CPUFREQ=${CPUFREQ}

# ------------------------------------------------------------------------------
echo -e "[ ${RED} Install dependencies ${NC} ]"
apt-get --reinstall install -y build-essential gfortran gfortran-4.2
apt-get --purge remove -y g77
apt-get --purge remove -y "^liblapack.*"
apt-get --purge remove -y "^libblas.*"
rm -rvf /usr/lib{,64}/atlas/

# ------------------------------------------------------------------------------
echo -e "[ ${RED} Download lapack-3.2.1 ${NC} ]"
cd ${TMP_DIR}
test ! -f lapack.tgz && \
    wget http://www.netlib.org/lapack/lapack.tgz
tar xzf lapack.tgz

echo -e "[ ${RED} Configure lapack-3.2.1 ${NC} ]"
cd lapack-3.2.1
sed -e 's/^OPTS *=/OPTS\t= -O2 -fPIC -m64/' \
    -e 's/^NOOPT *=/NOOPT\t=-O0 -fPIC -m64 /' \
    make.inc.example > make.inc

echo -e "[ ${RED} Build lapack-3.2.1 ${NC} ]"
cd SRC
make -j ${NPROCS}

# ------------------------------------------------------------------------------
echo -e "[ ${RED} Download atlas-3.8.3 ${NC} ]"
cd ${TMP_DIR}
test ! -f atlas3.8.3.tar.bz2 && \
    wget http://downloads.sourceforge.net/project/math-atlas/Stable/3.8.3/atlas3.8.3.tar.bz2
tar xjf atlas3.8.3.tar.bz2

# ------------------------------------------------------------------------------
echo -e "[ ${RED} Configure atlas-3.8.3 ${NC} ]"
cd ATLAS/
mkdir -p Linux_X64SSE2 && cd Linux_X64SSE2
# (try to) turn off cpu-throttling
cpufreq-selector -g performance

# if you don't want 64bit code remove the '-b 64' and '-fPIC' flags
../configure -b 64 -D c -DPentiumCPS=${CPUFREQ} \
    -Fa alg -fPIC \
    --with-netlib-lapack=../../../lapack-3.2.1/lapack_LINUX.a -Si cputhrchk 0

echo -e "[ ${RED} Build atlas-3.8.3 ${NC} ]"
# this takes a long time, go get some coffee, it should end without error
make build

# this will verify the build, also long running
make check
make ptcheck

# this will test the performance of your build and give you feedback on
# it. your numbers should be close to the test numbers at the end
make time

cd lib

# builds single threaded .so's
make shared

# builds multithreaded .so's
make ptshared

# ------------------------------------------------------------------------------
echo -e "[ ${RED} Install atlas-3.8.3 ${NC} ]"
# copy all of the atlas libs (and the lapack lib built with atlas)
cp -vf *.so  *.a /usr/lib/
ldconfig

# ------------------------------------------------------------------------------
echo -e "Installation successful!"

echo -e "You may want to clean up ${TMP_DIR}"

#echo -e "[ ${RED} Clean up ${TMP_DIR} ${NC} ]"
#
#echo $TMP_DIR
#exit 99



# # alternative!!!
# sudo apt-get install gfortran-4.2 -y
# sudo ln -sf /usr/bin/gfortran{-4.2,} 

# mkdir Linux_X64SSE2_gfortran-4.2
# cd Linux_X64SSE2_gfortran-4.2

# sudo cpufreq-selector -g performance
# ../configure -b 64 -D c -DPentiumCPS=2666 -Fa alg -fPIC --with-netlib-lapack=$HOME/src/lapack-3.2.1/lapack_LINUX.a

# make build

# make check
# make ptcheck

# make time

# cd lib

# make shared
# make ptshared

# sudo  cp  *.so  *.a /usr/lib


# echo $TMP_DIR
# exit 99

# # ------------------------------------------------------------------------------
# echo -e "[${RED} Cleaning up ${NC}]"
# rm -rf $TMP_DIR

# # ------------------------------------------------------------------------------
# echo "Installation successful!"


