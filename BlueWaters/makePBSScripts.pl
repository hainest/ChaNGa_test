use strict;
use warnings;
use Cwd qw(cwd);
use ChaNGa qw(%config $base_dir @theta @size);
use Getopt::Long qw(GetOptions);

my $runtime_hours = 4;
my $total_cores = 64;
GetOptions('hours=i' => \$runtime_hours, 'ncores=i' => \$total_cores);

for my $type (keys %config) {
	open my $fdOut, '>', "${type}.pbs" or die;

	my ($module, $mps, $server, $cores_per_node) = ('', '', 'xe', 32);

	if ($type =~ /gpu/i) {
		$module         = 'module load cudatoolkit/7.5.18-1.0502.10743.2.1';
		$server         = 'xk';
		$cores_per_node = 16;
#		$mps = "export CRAY_CUDA_MPS=1\n";
	}

	my $num_nodes = $total_cores / $cores_per_node;
	
	&print_header($type, $fdOut, $num_nodes, $cores_per_node, $server);
	print $fdOut "$module\n$mps\n";
	&print_commands($type, $fdOut, $num_nodes, $cores_per_node);

	open $fdOut, '>', "${type}.acc.pbs" or die;

	&print_header($type, $fdOut, $num_nodes, $cores_per_node, $server, 'acc');
	print $fdOut "$module\n$mps\n";
	&print_commands($type, $fdOut, $num_nodes, $cores_per_node, 'acc');
}

sub max($$) {
	my ($x,$y) = @_;
	return $x if($x >= $y);
	return $y;
}

sub print_commands() {
	my ($type, $fdOut, $num_nodes, $cores_per_node, $ext) = @_;
	$ext //= '';
	my $pes_per_node = $config{$type}{'pes_per_node'};

	my $threads = $config{$type}{'threads_per_pe'};
	for my $numparticles (@size) {
		my $cores_per_pe = $config{$type}{'cores_per_pe'};
		
		my $smp = '';
		if($type =~ /smp/i) {
			$smp = "++ppn $threads";
		}
		
		for my $t (@theta) {
			for my $b (@{$config{$type}{'bucketsize'}}) {
				my $dir       = "$type/$numparticles/$threads/$t/$b/$ext";
				my $total_pes = $num_nodes * $pes_per_node;
				my $prefix    = "$type+$numparticles+$threads+$t+$b";
				print $fdOut "aprun -n $total_pes -N $pes_per_node -d $cores_per_pe ";
				print $fdOut "$base_dir/src/$type/changa/ChaNGa $smp -v 1 $base_dir/$dir/${prefix}.param ";
				print $fdOut "1>$base_dir/$dir/stdout 2>$base_dir/$dir/stderr\n";
			}
		}
	}
}

sub print_header() {
	my ($type, $fdOut, $num_nodes, $cores_per_node, $server, $acc) = @_;
	$acc //= '';
	
	print $fdOut qq(#!/bin/sh

#PBS -l nodes=$num_nodes:ppn=$cores_per_node:$server
#PBS -l walltime=00:${runtime_hours}:00:00
#PBS -e $type/stderr$acc
#PBS -o $type/stdout$acc
#PBS -M thaines\@astro.wisc.edu
#PBS -m ae

export HUGETLB_DEFAULT_PAGE_SIZE=8M
module load craype-hugepages8M
);
}
