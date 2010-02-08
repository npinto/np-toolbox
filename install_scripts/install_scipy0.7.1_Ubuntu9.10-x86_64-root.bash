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

# ------------------------------------------------------------------------------
SCIPY=scipy-0.7.1
echo -e "[ ${RED} Download ${SCIPY} ${NC} ]"
cd ${TMP_DIR}
test ! -f ${SCIPY}.tar.gz && \
    wget http://downloads.sourceforge.net/sourceforge/scipy/${SCIPY}.tar.gz
tar xzf ${SCIPY}.tar.gz

echo -e "[ ${RED} Build ${SCIPY} ${NC} ]"
cd ${SCIPY}
python setup.py build

echo -e "[ ${RED} Remove previous installation ${NC} ]"
export PREVIOUS_INSTALL=$(cd $HOME && \
    python -c "import scipy; print scipy.__path__[0]" 2> /dev/null)
if [ $PREVIOUS_INSTALL ]; 
then echo "Uninstalling $PREVIOUS_INSTALL"; 
rm -rf $PREVIOUS_INSTALL;
fi;

echo -e "[ ${RED} Install ${NUMPY} ${NC} ]"
python setup.py install

# XXX: need (many) more tests here
echo -e "[ ${RED} Test ${SCIPY} (linalg problem) ${NC} ]"
(cd $HOME && python -c "from scipy import linalg") || exit 1

echo -e "[ ${RED} Test ${SCIPY} (version and blas support) ${NC} ]"
VERSION=$(cd $HOME && python -c "import scipy; print scipy.__version__")
DOTBLAS=$(cd $HOME && python -c "import scipy; print scipy.dot.__module__")

echo "VERSION=$VERSION"
echo "DOTBLAS=$DOTBLAS"

if [[ $VERSION != "0.7.1" || $DOTBLAS != "numpy.core._dotblas" ]] ; 
then echo "ERROR! see $TMP_DIR"; exit 1; 
fi;

echo -e "${SCIPY} has been successfuly installed!"

echo -e "You may want to clean up ${TMP_DIR}/${SCIPY}"
#rm -rf ${TMP_DIR}/${SCIPY}

