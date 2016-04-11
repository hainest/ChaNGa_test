#!/bin/sh

cur_dir=$PWD

cd charm
rm -rf bin include lib lib_so tmp VERSION net-linux-x86_64-cuda
./build charm++ net-linux-x86_64 cuda --enable-lbuserdata -j4 -optimize
./build ChaNGa net-linux-x86_64 cuda --enable-lbuserdata -j4 -optimize
cd $cur_dir/changa
./configure --with-cuda=$TACC_CUDA_DIR --with-cuda-level=35
make clean
make -j4
