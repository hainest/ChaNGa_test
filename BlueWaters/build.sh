#!/bin/sh

cur_dir=$PWD

cd charm
rm -rf bin include lib lib_so tmp VERSION net-linux-x86_64
./build charm++ net-linux-x86_64 --enable-lbuserdata -j4 -optimize
./build ChaNGa net-linux-x86_64 -j4 -optimize
cd $cur_dir/../changa
./configure
make -j4
mv ChaNGa ../ChaNGa_CPU
