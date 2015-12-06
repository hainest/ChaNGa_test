use strict;
use warnings;
use Cwd qw(cwd);
use ChaNGa qw(%config $base_dir);

my $num_nodes = $ARGV[0] // 1;
my $tasks_per_node = 16;
my $num_tasks = $num_nodes * $tasks_per_node;

for my $type (keys %config) {
	my $module = ($type=~/GPU/) ? 'module load cuda/6.5' : '';
	open my $fdOut, '>', "${type}.sbatch" or die;
	my ($letter,$partition) = ($type eq 'CPU') ? ('C','normal') : ('G','gpu');
	
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

PART: for my $numparticles (keys %{$config{$type}}) {
		for my $t (@{$config{$type}{$numparticles}{'threads_per_node'}}) {
			for my $b (@{$config{$type}{$numparticles}{'bucketsize'}}) {
				my $dir = "$type/$numparticles/$t/$b";
				print $fdOut "$base_dir/buckettest/$type/charmrun ++ppn $t +p $num_tasks $base_dir/buckettest/$type/ChaNGa -v 1 \"$dir/testdisk.param\"\n";
				last PART;
			}
		}
	}
}
