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

TMP_DIR=$(mktemp -d)
cd $TMP_DIR

# ------------------------------------------------------------------------------
echo -e "[${RED} Installing dependencies ${NC}]"
apt-get install swig glpk libglpk-dev libglpk0 python-cvxopt python-glpk -y

# ------------------------------------------------------------------------------
echo -e "[${RED} Downloading source code ${NC}]"
wget http://shogun-toolbox.org/archives/shogun/releases/0.9/sources/shogun-0.9.3.tar.bz2
tar xjf shogun-0.9.3.tar.bz2
cd shogun-0.9.3/src

# ------------------------------------------------------------------------------
echo -e "[${RED} Configuring ${NC}]"
#./configure --interfaces=libshogun,libshogunui,python,python_modular
./configure \
--interfaces=libshogun,libshogunui,python,python_modular \
--prefix=/usr --pydir=python2.6/dist-packages

# ------------------------------------------------------------------------------
echo -e "[${RED} Building ${NC}]"
make -j $NPROCS

# ------------------------------------------------------------------------------
echo -e "[${RED} Installing ${NC}]"
make install


# ------------------------------------------------------------------------------
echo -e "[${RED} Testing ${NC}]"
(cd $HOME && python -c "import shogun") || exit 1
VERSION=$(python -c 'import shogun.Classifier; print shogun.Classifier.Version_print_version()')
VERSION_RELEASE=$(python -c 'import shogun.Classifier; print shogun.Classifier.Version_get_version_release()')
VERSION_REVISION=$(python -c 'import shogun.Classifier; print shogun.Classifier.Version_get_version_revision()')

echo $VERSION
echo $VERSION_RELEASE
echo $VERSION_REVISION

CORRECT_VERSION_RELEASE='v0.9.3_r4889_2010-05-27_20:52_'

if [[ "$VERSION_RELEASE" != "$CORRECT_VERSION_RELEASE" ]]; then
echo "Error: incorrect version (got $VERSION_RELEASE instead of $CORRECT_VERSION_RELEASE)"; 
exit 1;
fi;

# ------------------------------------------------------------------------------
echo -e "[${RED} Cleaning up ${NC}]"
rm -rf $TMP_DIR

# ------------------------------------------------------------------------------
echo "Installation successful!"

