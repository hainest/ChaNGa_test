use strict;
use warnings;
use Cwd qw(cwd);
use ChaNGa qw(%config $base_dir @theta);

my $total_cores = 64;

for my $type (keys %config) {
	open my $fdOut, '>', "${type}.pbs" or die;

	# cpus_per_pe is redundant now, but will be useful when
	# testing multiple PEs per node later
	my ($module, $mps, $server, $cores_per_node, $cpus_per_pe) = ('', '', 'xe', 32, 1);

	if ($type =~ /gpu/i) {
		$module         = 'module load cudatoolkit/6.5.14-1.0502.9613.6.1';
		$server         = 'xk';
		$cores_per_node = 16;
		$cpus_per_pe    = 16;
		
		if($type !~ /smp/i) {
			$mps = "export CRAY_CUDA_MPS=1\n";
		}
	}

	my $num_nodes = $total_cores / $cores_per_node;

	&print_header($type, $fdOut, $num_nodes, $cores_per_node, $server);
	print $fdOut "$module\n$mps\n";
	&print_commands($type, $fdOut, $num_nodes, $cpus_per_pe);

	open $fdOut, '>', "${type}.acc.pbs" or die;
	$num_nodes = 1;

	&print_header($type, $fdOut, $num_nodes, $cores_per_node, $server);
	print $fdOut "$module\n$mps\n";
	&print_commands($type, $fdOut, $num_nodes, $cpus_per_pe);
}

sub print_commands($$$$) {
	my ($type, $fdOut, $num_nodes, $cpus_per_pe) = @_;
	for my $numparticles (keys %{$config{$type}}) {
		for my $threads (@{$config{$type}{$numparticles}{'threads_per_pe'}}) {
			my $smp = '';
			if($type =~ /smp/i) {
				$smp = '++ppn ' . $threads;
			}
			for my $pes_per_node (@{$config{$type}{$numparticles}{'pes_per_node'}}) {
				for my $t (@theta) {
					for my $b (@{$config{$type}{$numparticles}{'bucketsize'}}) {
						my $dir       = "$type/$numparticles/$threads/$t/$b";
						my $total_pes = $num_nodes * $threads * $pes_per_node;
						my $prefix    = "$type+$numparticles+$pes_per_node+$threads+$t+$b";
						print $fdOut "aprun -n $total_pes -N $pes_per_node -d $cpus_per_pe ";
						print $fdOut "$base_dir/src/$type/changa/ChaNGa $smp -v 1 $base_dir/$dir/${prefix}.param ";
						print $fdOut "1>$base_dir/$dir/stdout 2>$base_dir/$dir/stderr\n";
					}
				}
			}
		}
	}
}

sub print_header($$$$$) {
	my ($type, $fdOut, $num_nodes, $cores_per_node, $server) = @_;

	print $fdOut qq(#!/bin/sh

#PBS -l nodes=$num_nodes:ppn=$cores_per_node:$server
#PBS -l walltime=00:47:59:00
#PBS -e $type/stderr
#PBS -o $type/stdout
#PBS -M thaines\@astro.wisc.edu
#PBS -m ae

);
}
