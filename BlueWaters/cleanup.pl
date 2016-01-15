use strict;
use warnings;
use Cwd qw(cwd);
use ChaNGa qw(%config $base_dir @theta);

my @types = (@ARGV) ? @ARGV : keys %config;

for my $type (keys %config) {
	for my $numparticles (keys %{$config{$type}}) {
		for my $pes_per_node (@{$config{$type}{$numparticles}{'pes_per_node'}}) {
			for my $threads (@{$config{$type}{$numparticles}{'threads_per_pe'}}) {
				for my $theta (@theta) {
					for my $b (@{$config{$type}{$numparticles}{'bucketsize'}}) {
						my $prefix = "$type+$numparticles+$pes_per_node+$threads+$theta+$b";
						unlink "$base_dir/$type/$numparticles/$threads/$theta/$b/$prefix.out";
					}
				}
			}
		}
	}
}
