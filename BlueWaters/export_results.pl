use strict;
use warnings;
use Cwd qw(cwd);
use ChaNGa qw(%config @theta);
use IO::Compress::Gzip qw(gzip);
use File::Copy qw(move);

my $simTime = 0.005;                      # 5 Myrs
my $snapshot_suffix = sprintf('%06s',int($simTime*1e3));

for my $type (keys %config) {
for my $numparticles (keys %{$config{$type}}) {
for my $pes_per_node (@{$config{$type}{$numparticles}{'pes_per_node'}}) {
for my $threads (@{$config{$type}{$numparticles}{'threads_per_pe'}}) {
	for my $t (@theta) {
		for my $b (@{$config{$type}{$numparticles}{'bucketsize'}}) {
			my $dir    = "$type/$numparticles/$pes_per_node/$threads/$t/$b";
			my $prefix = "$type+$numparticles+$pes_per_node+$threads+$t+$b";
			
			if (-e "$dir/acc/$prefix.acc.out.000000.acc2") {
				move("$dir/acc/$prefix.acc.out.000000.acc2","$dir/acc/$prefix.acc");
			}
			if (! -e "$dir/acc/$prefix.acc.gz") {
				gzip("$dir/acc/$prefix.acc" => "$dir/acc/$prefix.acc.gz",'-level'=>9);
			}
			
			print "$dir/$prefix.out.log $dir/$prefix.out.$snapshot_suffix ";
			print "$dir/acc/$prefix.acc.gz ";
		}
	}
}}}}
