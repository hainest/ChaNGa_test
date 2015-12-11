use strict;
use warnings;
use Cwd qw(cwd);
use ChaNGa qw(%config $base_dir);

my $num_nodes      = $ARGV[0] // 4;
my $tasks_per_node = 16;
my $num_tasks      = $num_nodes * $tasks_per_node;

sub write_header($$$$) {
	my ($fdOut, $type, $module, $partition) = @_;

	print $fdOut qq(#!/bin/sh

#SBATCH --job-name=$type
#SBATCH --partition=$partition
#SBATCH --time=0-47:45:00    # run time in days-hh:mm:ss
#SBATCH --nodes=$num_nodes
#SBATCH --ntasks=$num_tasks
#SBATCH --ntasks-per-node=$tasks_per_node
#SBATCH --error=${type}/stderr
#SBATCH --output=${type}/sdtout
#SBATCH --mail-type=end,fail
#SBATCH --mail-user=thaines\@astro.wisc.edu

$module
);
}

for my $type (keys %config) {
	open my $fdOut, '>', "${type}.sbatch" or die;
	my ($letter, $partition) = ($type eq 'CPU') ? ('C', 'normal') : ('G', 'gpu');

	write_header($fdOut, $type, ($type =~ /GPU/) ? 'module load cuda/6.5' : '', $partition);

	for my $numparticles (keys %{$config{$type}}) {
		for my $threads (@{$config{$type}{$numparticles}{'threads_per_node'}}) {
			for my $theta ('0.1', '0.3', '0.5', '0.7', '0.9') {
				for my $b (@{$config{$type}{$numparticles}{'bucketsize'}}) {
					my $dir = "$type/$numparticles/$threads/$theta/$b";
					my $p = $num_nodes * $threads;
					print $fdOut "$base_dir/$type/charmrun ++ppn $threads +p $p $base_dir/$type/ChaNGa -v 1 \"$dir/testdisk.param\"\n";
				}
			}
		}
	}
}
