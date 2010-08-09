#!/bin/basj

red='\e[0;31m'
RED='\e[1;31m'
blue='\e[0;34m'
BLUE='\e[1;34m'
cyan='\e[0;36m'
CYAN='\e[1;36m'
NC='\e[0m' # No Color

# TODO: install sdk in /usr/local/cuda/sdk instead of /home/thor/

# ------------------------------------------------------------------------------
# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# ------------------------------------------------------------------------------
NPROCS=$(grep processor /proc/cpuinfo | wc -l)

TMP_DIR=$(mktemp -d)
cd $TMP_DIR

echo -e "[ ${RED}Shuting down X/gdm${NC} ]"
#/etc/init.d/gdm stop
service gdm stop
killall -9 X
killall -9 Xorg
rmmod -v nvidia

# {un,}install necessary stuff from ubuntu repos
echo -e "[ ${RED}Uninstalling previous installation${NC} ]"
apt-get --purge remove nvidia"*" -y
echo -e "[ ${RED}Installing dependencies${NC} ]"
apt-get install libc6-dev-i386 build-essential libglut3-dev libxmu-dev libxi-dev gcc-4.3 g++-4.3 -y

# ------------------------------------------------------------------------------
echo -e "[${RED} Installing driver ${NC}]"
wget http://developer.download.nvidia.com/compute/cuda/3_1/drivers/devdriver_3.1_linux_64_256.40.run
kill -9 $(ps aux | grep /usr/bin/X) 2> /dev/null
sh devdriver_3.1_linux_64_256.40.run --ui=none --no-questions --accept-license -X

# ------------------------------------------------------------------------------
echo -e "[${RED} Initializing device(s) ${NC}]"
rm -vf /etc/init.d/{init_,}cuda.sh
cat << EOF > /etc/init.d/init_cuda.sh
#!/bin/bash

modprobe -v nvidia

if [ "\$?" -eq 0 ]; then

# Count the number of NVIDIA controllers found.
N3D=\$(lspci | grep -i NVIDIA | grep "3D controller" | wc -l)
NVGA=\$(lspci | grep -i NVIDIA | grep "VGA compatible controller" | wc -l)

N=\$(expr \$N3D + \$NVGA - 1)
for i in \$(seq 0 \$N); do
echo "Initializing device \$i";
mknod -m 666 /dev/nvidia\$i c 195 \$i;
nvidia-smi --gpu=\$i --compute-mode-rules=1;
done

mknod -m 666 /dev/nvidiactl c 195 255

else
exit 1
fi

EOF

chmod +x /etc/init.d/init_cuda.sh
update-rc.d init_cuda.sh defaults
modprobe -v nvidia 2> /dev/null
/etc/init.d/init_cuda.sh

if [ ! $(echo $LD_LIBRARY_PATH | grep /usr/local/cuda/lib64) ]; 
then echo -e "[${RED} Updating LD_LIBRARY_PATH ${NC}]";
echo -e "export LD_LIBRARY_PATH=/usr/local/cuda/lib64:\$LD_LIBRARY_PATH" >> /etc/zsh/zshenv;
source /etc/zsh/zshenv;
fi;

# ------------------------------------------------------------------------------
echo -e "[${RED} Installing toolkit ${NC}]"
wget http://developer.download.nvidia.com/compute/cuda/3_1/toolkit/cudatoolkit_3.1_linux_64_ubuntu9.10.run
sh ./cudatoolkit_3.1_linux_64_ubuntu9.10.run --noexec --target cudatoolkit/
cd ./cudatoolkit && ./install-linux.pl auto && cd ..
nvcc --version

# ------------------------------------------------------------------------------
echo -e "[${RED} Installing sdk ${NC}]"
wget http://developer.download.nvidia.com/compute/cuda/3_1/sdk/gpucomputingsdk_3.1_linux.run
rm -rf /home/thor/NVIDIA_GPU_Computing_SDK/
chmod -vR a+rwx $TMP_DIR
sudo -u thor sh $TMP_DIR/gpucomputingsdk_3.1_linux.run --noexec --target cudasdk/
cd ./cudasdk && sudo -u thor ./install-sdk-linux.pl --prefix=/home/thor/NVIDIA_GPU_Computing_SDK --cudaprefix=/usr/local/cuda && cd ../

# compile SDK
echo -e "[${RED} Compiling sdk ${NC}]"
cd /home/thor/NVIDIA_GPU_Computing_SDK/C
mv -vf common/common.mk{,.bak}
sudo -u thor sed -e 's/^NVCCFLAGS := $/NVCCFLAGS := --compiler-bindir=\/usr\/bin\/gcc-4.3/' common/common.mk.bak > common/common.mk
sudo -u thor make -j $NPROCS && ./bin/linux/release/deviceQuery < /dev/null

# tests
echo -e "[${RED} Testing sdk ${NC}]"
for f in ./bin/linux/release/*; do $f < /dev/null &> /dev/null || echo "ERROR: $f"; done;

# ------------------------------------------------------------------------------
echo -e "You may want to clean up ${TMP_DIR}"
#rm -rf $TMP_DIR

# ------------------------------------------------------------------------------
#echo "Installation successful!"
