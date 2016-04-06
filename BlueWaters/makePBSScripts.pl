use strict;
use warnings;
use Cwd qw(cwd);
use ChaNGa qw(%config $base_dir @theta);

my $total_cores = 64;

for my $type (keys %config) {
	open my $fdOut, '>', "${type}.pbs" or die;

	my ($module, $mps, $server, $cores_per_node) = ('', '', 'xe', 32);

	if ($type =~ /gpu/i) {
		$module         = 'module load cudatoolkit/7.0.28-1.0502.10742.5.1';
		$server         = 'xk';
		$cores_per_node = 16;
	}
	
	# The non-SMP GPU version is severely broken.
	if ($type eq 'GPU2') {
		$cores_per_node = 2;
	} elsif ($type eq 'GPU1') {
		$cores_per_node = 1;
	}
	
	if($type !~ /smp/i) {
		$mps = "export CRAY_CUDA_MPS=1\n";
	}

	my $num_nodes = $total_cores / $cores_per_node;
	
	&print_header($type, $fdOut, $num_nodes, $cores_per_node, $server);
	print $fdOut "$module\n$mps\n";
	&print_commands($type, $fdOut, $num_nodes, $cores_per_node);

	open $fdOut, '>', "${type}.acc.pbs" or die;
	$num_nodes = 1;

	&print_header($type, $fdOut, $num_nodes, $cores_per_node, $server, 'acc');
	print $fdOut "$module\n$mps\n";
	&print_commands($type, $fdOut, $num_nodes, $cores_per_node, 'acc');
}

sub print_commands() {
	my ($type, $fdOut, $num_nodes, $cores_per_node, $ext) = @_;
	$ext //= '';
	for my $numparticles (keys %{$config{$type}}) {
		for my $threads (@{$config{$type}{$numparticles}{'threads_per_pe'}}) {
			my $smp = '';
			if($type =~ /smp/i) {
				$smp = '++ppn ' . $threads;
			}
			for my $pes_per_node (@{$config{$type}{$numparticles}{'pes_per_node'}}) {
				my $cores_per_pe = int($cores_per_node / $pes_per_node);
				$cores_per_pe = $cores_per_pe > 0 ? $cores_per_pe : 1;
				for my $t (@theta) {
					for my $b (@{$config{$type}{$numparticles}{'bucketsize'}}) {
						my $dir       = "$type/$numparticles/$pes_per_node/$threads/$t/$b/$ext";
						my $total_pes = $num_nodes * $pes_per_node;
						my $prefix    = "$type+$numparticles+$pes_per_node+$threads+$t+$b";
						print $fdOut "aprun -n $total_pes -N $pes_per_node -d $cores_per_pe ";
						print $fdOut "$base_dir/src/$type/changa/ChaNGa $smp -v 1 $base_dir/$dir/${prefix}.param ";
						print $fdOut "1>$base_dir/$dir/stdout 2>$base_dir/$dir/stderr\n";
					}
				}
			}
		}
	}
}

sub print_header() {
	my ($type, $fdOut, $num_nodes, $cores_per_node, $server, $acc) = @_;
	$acc //= '';
	
	print $fdOut qq(#!/bin/sh

#PBS -l nodes=$num_nodes:ppn=$cores_per_node:$server
#PBS -l walltime=00:47:59:00
#PBS -e $type/stderr$acc
#PBS -o $type/stdout$acc
#PBS -M thaines\@astro.wisc.edu
#PBS -m ae

export HUGETLB_DEFAULT_PAGE_SIZE=8M
module load craype-hugepages8M
);
}
