#!/bin/sh

# exit on error
set -e

cur_dir=$PWD

# Fix for RCA module issues (https://charm.cs.illinois.edu/redmine/issues/534)
export PE_PKGCONFIG_LIBS=cray-rca:$PE_PKGCONFIG_LIBS

cd charm
rm -rf bin include lib lib_so tmp VERSION gni-crayxe-hugepages-smp
./build ChaNGa gni-crayxe hugepages smp --enable-lbuserdata -j4 -optimize

cd $cur_dir/changa
./configure
make clean
make -j4
