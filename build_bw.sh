#!/bin/sh

cwd=$(pwd)
perl -I\$cwd $cwd/build_driver.pl 1>$cwd/src/build.out 2>$cwd/src/build.err