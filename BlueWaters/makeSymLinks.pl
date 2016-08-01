use strict;
use warnings;
use ChaNGa qw(%config $base_dir);

for my $type (keys %config) {
	$type =~ m/^([A-Za-z]+)\d+/;
	my $clean_type = $1 // $type;
	symlink("$base_dir/src/$clean_type/changa/ChaNGa","$base_dir/$type/ChaNGa");
}