use strict;
use warnings;
use Cwd qw(cwd);
use ChaNGa qw(%config);

my $baseDir = "$ENV{'HOME'}/ChaNGa";

for my $type (keys %config) {
	my $module = ($type=~/GPU/) ? 'module load cuda/6.5' : '';
	open my $fdOut, '>', "${type}.sbatch" or die;
	my ($letter,$partition) = ($type eq 'CPU') ? ('C','normal') : ('G','gpu');
	
	print $fdOut qq(#!/bin/sh

#SBATCH --job-name=$type
#SBATCH --partition=$partition
#SBATCH --time=0-1:00:00    # run time in days-hh:mm:ss
#SBATCH --nodes=1
#SBATCH --ntasks=16
#SBATCH --ntasks-per-node=16
#SBATCH --error=${type}.err
#SBATCH --output=${type}.out
#SBATCH --mail-type=end,fail
#SBATCH --mail-user=thaines\@astro.wisc.edu

$module
);

PART: for my $numparticles (keys %{$config{$type}}) {
		for my $t (@{$config{$type}{$numparticles}{'threads'}}) {
			for my $b (@{$config{$type}{$numparticles}{'bucketsize'}}) {
				my $dir = "$type/$numparticles/$t/$b";
				print $fdOut "$baseDir/$type/changa/charmrun ++ppn 1 +p $t ++local $baseDir/$type/changa/ChaNGa -v 1 \"$dir/testdisk.param\"\n";
				last PART;
			}
		}
	}
}
