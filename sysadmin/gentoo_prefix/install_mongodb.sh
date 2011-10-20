#!/bin/bash

LDFLAGS="-L /usr/lib -L $EPREFIX/usr/lib" CXXLFAGS="-I /usr/include -I $EPREFIX/usr/include" CXX=g++ emerge mongodb
