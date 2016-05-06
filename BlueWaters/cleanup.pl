use strict;
use warnings;
use File::Copy qw(move);
use ChaNGa qw(%config $base_dir @theta @size);

my $snapshot_suffix = '000005';

$base_dir = $ARGV[0] if @ARGV;

for my $type (keys %config) {
my $threads = $config{$type}{'threads_per_pe'};
for my $numparticles (@size) {
for my $t (@theta) {
for my $b (@{$config{$type}{'bucketsize'}}) {
	my $prefix  = "$type+$numparticles+$threads+$t+$b";
	my $dir     = "$base_dir/$type/$numparticles/$threads/$t/$b/";

	move("$dir/acc/$prefix.acc.out.000000.acc2","$dir/acc/$prefix.acc");
#	unlink "$dir/$prefix.out.$snapshot_suffix";

	unlink "$dir/acc/$prefix.acc.out.000000";
	unlink "$dir/acc/$prefix.acc.out.000000.dom";
	unlink "$dir/acc/$prefix.acc.out.000000.key";
	unlink "$dir/acc/$prefix.acc.out.000000.rung";
	}
}}}
