use strict;
use warnings;
use ChaNGa qw(%config);

my $srcDir = "$ENV{'HOME'}/src";

for my $type (keys %config) {
	symlink("$srcDir/$type/changa/ChaNGa","$type/ChaNGa") or die "$!\n";
}
