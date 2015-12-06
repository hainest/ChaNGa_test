use strict;
use warnings;
use Cwd qw(cwd);
use ChaNGa qw(%config);

my $pwd = &cwd();
my @types = (@ARGV) ? @ARGV : keys %config;

for my $type ( keys %config ) {
	for my $n ( keys %{ $config{$type} } ) {
		for my $t ( @{ $config{$type}{$n}{'threads'} } ) {
			for my $b ( @{ $config{$type}{$n}{'bucketsize'} } ) {
				unlink "$pwd/$type/$n/$t/$b/testdisk.000005";
			}
		}
	}
}
