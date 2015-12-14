use strict;
use warnings;
use Cwd qw(cwd);
use ChaNGa qw(%config $base_dir);

my @types = (@ARGV) ? @ARGV : keys %config;

for my $type (keys %config) {
	for my $numparticles (keys %{$config{$type}}) {
		for my $threads (@{$config{$type}{$numparticles}{'threads_per_node'}}) {
			for my $theta ('0.1', '0.3', '0.5', '0.7', '0.9') {
				for my $b (@{$config{$type}{$numparticles}{'bucketsize'}}) {
					unlink "$base_dir/$type/$numparticles/$threads/$theta/$b/testdisk.$type+$numparticles+$threads+$theta+$b";
				}
			}
		}
	}
}
