#!/bin/bash

source $(dirname $0)/init.sh

(cd $EPREFIX/usr/local/portage && $EPREFIX/usr/portage/scripts/ecopy dev-db/mongodb)

echo "dev-db/mongodb v8" >> $EPREFIX/etc/portage/package.use/mongodb
echo "dev-lang/v8 **" >> $EPREFIX/etc/portage/package.keywords/mongodb
echo "dev-db/mongodb **" >> $EPREFIX/etc/portage/package.keywords/mongodb

LDFLAGS="-L /usr/lib -L $EPREFIX/usr/lib" CXXFLAGS="-I /usr/include -I $EPREFIX/usr/include" CXX=g++ emerge -v mongodb

