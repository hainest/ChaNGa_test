#!/bin/sh

# exit on error
set -e

cur_dir=$PWD

# Fix for RCA module issues (https://charm.cs.illinois.edu/redmine/issues/534)
export PE_PKGCONFIG_LIBS=cray-rca:$PE_PKGCONFIG_LIBS

cd charm
rm -rf bin include lib lib_so tmp VERSION gni-crayxe-hugepages-cuda
export CUDA_DIR=$CRAY_CUDATOOLKIT_DIR
./build ChaNGa gni-crayxe hugepages cuda --enable-lbuserdata -j4 -optimize

cd $cur_dir/changa
./configure --with-cuda=$CRAY_CUDATOOLKIT_DIR --with-cuda-level=35
make clean
make -j4
