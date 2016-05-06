use strict;
use warnings;
use File::Copy qw(move);
use ChaNGa qw(%config @theta @size);

my $base_dir = 'results';

for my $type ( 'CPU-SMP' ) {
	my $threads = $config{$type}{'threads_per_pe'};
	for my $numparticles (@size) {
		for my $t (@theta) {
			for my $b ( @{ $config{$type}{'bucketsize'} } ) {
				my $dir    = "$base_dir/$type/$numparticles/$threads/$t/$b";
				my $prefix_old = "$type+$numparticles+32+$t+$b";
				my $prefix_new = "$type+$numparticles+$threads+$t+$b";
			
				for my $suffix ('out.log', 'param') {
					move "$dir/$prefix_old.$suffix", "$dir/$prefix_new.$suffix";
				}
				
				$dir .= "/acc";
				for my $suffix ('acc.out.log', 'param', 'acc') {
					move "$dir/$prefix_old.$suffix", "$dir/$prefix_new.$suffix";
				}
}}}}