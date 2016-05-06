use strict;
use warnings;
use ChaNGa qw(%config $base_dir);

for my $type ( keys %config ) {
	symlink("$base_dir/src/$type/changa/ChaNGa", "$base_dir/$type/ChaNGa");
}
