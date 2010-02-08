#!/bin/sh

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

TMP_DIR=$(mktemp -d)

cd $TMP_DIR

# download
echo "Downloading tarball in $TMP_DIR"
wget http://downloads.sourceforge.net/sourceforge/scipy/scipy-0.7.1.tar.gz
tar xzf scipy-0.7.1.tar.gz
cd scipy-0.7.1

# build
echo "Building"
python setup.py build

# uninstall
cd ../
export PREVIOUS_INSTALL=$(python -c "import scipy; print scipy.__path__[0]" 2> /dev/null)
if [ $PREVIOUS_INSTALL ]; 
then echo "Uninstalling $PREVIOUS_INSTALL"; 
rm -rf $PREVIOUS_INSTALL;
fi;
cd -

# install
echo "Installing"
python setup.py install

# small tests
echo "Testing (linalg problem)"
(cd $HOME && python -c "from scipy import linalg")

# cleaning up
echo "Cleaning $TMP_DIR"
rm -rf $TMP_DIR

VERSION=$(cd $HOME && python -c "import scipy; print scipy.__version__")
DOTBLAS=$(cd $HOME && python -c "import scipy; print scipy.dot.__module__")

echo "VERSION=$VERSION"
echo "DOTBLAS=$DOTBLAS"

if [[ $VERSION != "0.7.1" || $DOTBLAS != "numpy.core._dotblas" ]] ; 
then echo "ERROR! see $TMP_DIR"; exit 1; 
fi;

echo "scipy $VERSION has been installed"

# cleaning up
echo "Cleaning $TMP_DIR"
rm -rf $TMP_DIR
