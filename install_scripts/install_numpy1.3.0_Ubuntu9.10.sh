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
wget http://downloads.sourceforge.net/sourceforge/numpy/numpy-1.3.0.tar.gz
tar xzf numpy-1.3.0.tar.gz
cd numpy-1.3.0

# config
echo "Configuring"
cp -vf site.cfg.example site.cfg

cat << EOF >> site.cfg

# numpy's configuration on thor nodes

[DEFAULT]
library_dirs = /usr/lib
include_dirs = /usr/include

[blas_opt]
libraries = ptf77blas, ptcblas, atlas

[lapack_opt]
libraries = lapack, ptf77blas, ptcblas, atlas
EOF

# build
echo "Building"
python setup.py build

# uninstall
cd ../
export PREVIOUS_INSTALL=$(python -c "import numpy; print numpy.__path__[0]" 2> /dev/null)
if [ $PREVIOUS_INSTALL ]; 
then echo "Uninstalling $PREVIOUS_INSTALL"; 
rm -rf $PREVIOUS_INSTALL;
fi;
cd -

# install
echo "Installing"
python setup.py install

# small tests
echo "Testing (lapack problem)"
(cd $HOME && python -c "from numpy.linalg import lapack_lite")

VERSION=$(cd $HOME && python -c "import numpy; print numpy.__version__")
DOTBLAS=$(cd $HOME && python -c "import numpy; print numpy.dot.__module__")

echo "VERSION=$VERSION"
echo "DOTBLAS=$DOTBLAS"

if [[ $VERSION != "1.3.0" || $DOTBLAS != "numpy.core._dotblas" ]] ; 
then echo "ERROR! see $TMP_DIR"; exit 1; 
fi;

echo "numpy $VERSION has been installed"

# cleaning up
echo "Cleaning $TMP_DIR"
rm -rf $TMP_DIR

