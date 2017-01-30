use strict;
use warnings;
use Cwd qw(cwd);
use ChaNGa qw(get_all_options);

use Getopt::Long qw(GetOptions);

my $remove_snapshot = 0;
my $base_dir = cwd();

GetOptions(
	'remove-snapshot!' => \$remove_snapshot,
	'base_dir=s', \$base_dir
);

my $snapshot_suffix = sprintf('%06s',int($ChaNGa::sim_time*1e3));

for my $o ( get_all_options() ) {
	my $dir = "$base_dir/" . join('/', $o->listify);
	unlink glob "$dir/acc/acc.out.*";
	unlink "$dir/out.$snapshot_suffix" if $remove_snapshot;
}
