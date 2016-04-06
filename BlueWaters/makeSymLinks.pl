use strict;
use warnings;
use ChaNGa qw(%config $base_dir);

for my $type ( keys %config ) {
	my $clean_type = $type =~ m/^([A-Za-z]+)\d+/ ? $1 : $type;
	symlink("$base_dir/src/$clean_type/changa/ChaNGa", "$base_dir/$type/ChaNGa");
}
