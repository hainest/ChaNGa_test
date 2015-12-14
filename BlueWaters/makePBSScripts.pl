use strict;
use warnings;
use Cwd qw(cwd);
use ChaNGa qw(%config $base_dir);

for my $type (keys %config) {
	open my $fdOut, '>', "${type}.sbatch" or die;
	my $module = ($type =~ /GPU/) ? 'module load cudatoolkit/6.5.14-1.0502.9613.6.1' : '';
	my $num_nodes = 2; # 64 cores

	print $fdOut qq(#!/bin/sh

#PBS -l nodes=$num_nodes:ppn=32:xe
#PBS -l walltime=47:45:00
#PBS -N $type
#PBS -e stderr
#PBS -o stdout
#PBS -m ea
#PBS -M thaines\@astro.wisc.edu

$module
);

	for my $numparticles (keys %{$config{$type}}) {
		for my $threads (@{$config{$type}{$numparticles}{'threads_per_node'}}) {
			for my $theta ('0.1', '0.3', '0.5', '0.7', '0.9') {
				for my $b (@{$config{$type}{$numparticles}{'bucketsize'}}) {
					my $dir = "$type/$numparticles/$threads/$theta/$b";
					my $p = $num_nodes * $threads;
					print $fdOut "aprun -n $p -N $threads $base_dir/$type/changa/ChaNGa -v 1 $dir/testdisk.param\n";
				}
			}
		}
	}
	
	open $fdOut, '>', "${type}.acc.sbatch" or die;
	$num_nodes = 1;

	print $fdOut qq(#!/bin/sh

#PBS -l nodes=$num_nodes:ppn=32:xe
#PBS -l walltime=47:45:00
#PBS -N $type
#PBS -e stderr
#PBS -o stdout
#PBS -m ea
#PBS -M thaines\@astro.wisc.edu

$module
);

	for my $numparticles (keys %{$config{$type}}) {
		for my $threads (@{$config{$type}{$numparticles}{'threads_per_node'}}) {
			for my $theta ('0.1', '0.3', '0.5', '0.7', '0.9') {
				for my $b (@{$config{$type}{$numparticles}{'bucketsize'}}) {
					my $dir = "$type/$numparticles/$threads/$theta/$b/acc";
					print $fdOut "aprun -N 1 -n 1 $base_dir/$type/ChaNGa -v 1 \"$dir/testdisk.param\"\n";
				}
			}
		}
	}
}
