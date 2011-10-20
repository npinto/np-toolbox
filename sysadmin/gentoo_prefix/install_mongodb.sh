#!/bin/bash

source $(dirname $0)/update_env.sh

#mkdir -p $EPREFIX/usr/local/portage
(cd $EPREFIX/usr/local/portage && $EPREFIX/usr/portage/scripts/ecopy dev-db/mongodb)

# USE
echo "dev-db/mongodb v8" >> $EPREFIX/etc/portage/package.use/mongodb

# KEYWORDS
echo "dev-lang/v8 **" >> $EPREFIX/etc/portage/package.keywords/mongodb
echo "dev-db/mongodb **" >> $EPREFIX/etc/portage/package.keywords/mongodb

#emerge -v v8
#emerge -av mongodb

LDFLAGS="-L /usr/lib -L $EPREFIX/usr/lib" CXXLFAGS="-I /usr/include -I $EPREFIX/usr/include" CXX=g++ emerge -v mongodb

#(cd $EPREFIX/usr/local/portage && $EPREFIX/usr/portage/scripts/ecopy dev-lang/spidermonkey)
#echo 'dev-lang/spidermonkey **' >> $EPREFIX/etc/portage/package.use/mongodb



