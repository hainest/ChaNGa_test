#!/bin/sh

# Exit on errors
set -e

$base_dir=$PWD

for $dir in CPU CPU-SMP;
do
	echo -n "Updating $dir/charm... "
	cd $base_dir/$dir/charm
	git pull 1>$base_dir/update.out 2>$base_dir/update.err
	echo "Done."
	echo -n "Updating $dir/changa... "
	cd ../changa
	git pull 1>$base_dir/update.out 2>$base_dir/update.err
	echo "Done."
done

for $dir in GPU GPU-SMP;
do
	echo -n "Updating $dir/charm... "
	cd $base_dir/$dir/charm
	git pull 1>$base_dir/update.out 2>$base_dir/update.err
	git pull origin charm 1>$base_dir/update.out 2>$base_dir/update.err
	echo "Done."
	echo -n "Updating $dir/changa... "
	cd ../changa
	git pull 1>$base_dir/update.out 2>$base_dir/update.err
	git pull origin master 1>$base_dir/update.out 2>$base_dir/update.err
	echo "Done."
done

