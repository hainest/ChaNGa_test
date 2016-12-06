use strict;
use warnings;
use Cwd qw(cwd);
use ChaNGa qw(%config $base_dir @theta @size);
use Getopt::Long qw(GetOptions);

my ($cpu_time, $gpu_time) = ('00:04:30:00', '00:01:00:00');
my $total_cores = 64;
GetOptions('cpu_time=s' => \$cpu_time, 'gpu_time=s' => \$gpu_time) or exit;

for my $type (keys %config) {
	open my $fdOut, '>', "${type}.pbs" or die;

	my ($server, $cores_per_node, $time) = ('xe', 32, $cpu_time);

	if ($type =~ /gpu/i) {
		$server         = 'xk';
		$cores_per_node = 16;
		$time			= $gpu_time;
	}

	my $num_nodes = $total_cores / $cores_per_node;
	
	&print_header($type, $fdOut, $num_nodes, $cores_per_node, $server, $time);
	&print_commands($type, $fdOut, $num_nodes, $cores_per_node);
	print $fdOut "\n\n";
	&print_commands($type, $fdOut, $num_nodes, $cores_per_node, 'acc');
}

sub print_commands() {
	my ($type, $fdOut, $num_nodes, $cores_per_node, $ext) = @_;
	$ext //= '';
	my $pes_per_node = $config{$type}{'pes_per_node'};

	for my $threads (@{$config{$type}{'threads_per_pe'}}) {
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
		}}
	}}
}

sub print_header() {
	my ($type, $fdOut, $num_nodes, $cores_per_node, $server, $time) = @_;
	
	print $fdOut qq(#!/bin/sh

#PBS -l nodes=$num_nodes:ppn=$cores_per_node:$server
#PBS -l walltime=${time}
#PBS -e $type/stderr
#PBS -o $type/stdout
#PBS -M thaines\@astro.wisc.edu
#PBS -m ae

export HUGETLB_DEFAULT_PAGE_SIZE=8M
module load craype-hugepages8M

);
}
