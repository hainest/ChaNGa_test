use strict;
use warnings;
use Cwd qw(cwd);
use ChaNGa qw(%config $base_dir);

my @types = (@ARGV) ? @ARGV : keys %config;

for my $type ( keys %config ) {
	for my $n ( keys %{ $config{$type} } ) {
		for my $t ( @{ $config{$type}{$n}{'threads_per_node'} } ) {
			for my $b ( @{ $config{$type}{$n}{'bucketsize'} } ) {
				unlink "$base_dir/$type/$n/$t/$b/testdisk.000005";
			}
		}
	}
}
