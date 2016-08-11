use strict;
use warnings;
use File::Copy qw(move);
use Getopt::Long qw(GetOptions);
use ChaNGa qw(%config $base_dir @theta @size);

my $remove_snapshot = 0;
GetOptions('remove-snapshot!' => \$remove_snapshot);

if (@ARGV < 1) {
	die "Usage: $0 suffix [base_dir] [--remove-snapshot]\n";
}

my $snapshot_suffix = shift @ARGV;
$base_dir = $ARGV[1] if @ARGV;

for my $type (keys %config) {
my $threads = $config{$type}{'threads_per_pe'};
for my $numparticles (@size) {
for my $t (@theta) {
for my $b (@{$config{$type}{'bucketsize'}}) {
	my $prefix  = "$type+$numparticles+$threads+$t+$b";
	my $dir     = "$base_dir/$type/$numparticles/$threads/$t/$b/";

	move("$dir/acc/$prefix.acc.out.000000.acc2","$dir/acc/$prefix.acc");
	unlink "$dir/$prefix.out.$snapshot_suffix" if $remove_snapshot;

	unlink "$dir/acc/$prefix.acc.out.000000";
	unlink "$dir/acc/$prefix.acc.out.000000.dom";
	unlink "$dir/acc/$prefix.acc.out.000000.key";
	unlink "$dir/acc/$prefix.acc.out.000000.rung";
	}
}}}
