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
echo -e "[${RED} Installing dependencies ${NC}]"
apt-get install libav{codec,format,util}-dev libswscale-dev -y

# ------------------------------------------------------------------------------
echo -e "[${RED} Downloading source code ${NC}]"
sudo -u thor mkdir -p $HOME/projects/
cd $HOME/projects/
rm -rf pyffmpeg-np
sudo -u thor git clone git@github.com:npinto/pyffmpeg-np.git

# ------------------------------------------------------------------------------
echo -e "[${RED} Building ${NC}]"
cd pyffmpeg-np
sudo -u thor python setup.py build

# ------------------------------------------------------------------------------
echo -e "[${RED} Installing (develop) 3${NC}]"
cd pyffmpeg-np
python setup.py develop

# ------------------------------------------------------------------------------
echo -e "[${RED} Testing (simple) 3${NC}]"
SIMPLE_PY=/home/thor/projects/pyffmpeg-np/examples/simple.py
if [ ! $(sudo -u thor python $SIMPLE_PY | grep Done) ]; then 
echo "Error: $SIMPLE_PY failed!"; 
exit 1;
fi;

# ------------------------------------------------------------------------------0
echo "Installation successful!"