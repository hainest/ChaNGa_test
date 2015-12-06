use strict;
use warnings;
use Cwd qw(cwd);
use ChaNGa qw(%config);

my $pwd = &cwd();
my @types = (@ARGV) ? @ARGV : keys %config;

for my $type ( @types ) {
    for my $n ( keys %{ $config{$type} } ) {
        for my $t ( '0.1', '0.3', '0.5', '0.7', '0.9' ) {
		unlink "$pwd/$type/$n/theta$t/testdisk.000005";
		unlink "$pwd/$type/$n/theta$t/acc/testdisk.000005.000000";
		unlink "$pwd/$type/$n/theta$t/acc/testdisk.000005.000000.dom";
		unlink "$pwd/$type/$n/theta$t/acc/testdisk.000005.000000.iord";
		unlink "$pwd/$type/$n/theta$t/acc/testdisk.000005.000000.key";
		unlink "$pwd/$type/$n/theta$t/acc/testdisk.000005.000000.rung";
		}
	}
}
