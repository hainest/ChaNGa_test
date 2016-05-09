use strict;
use warnings;
use File::Copy qw(move);
use ChaNGa qw(%config @theta @size);

my $base_dir = 'results';

my $type_old = 'GPU-SMP-Simon+Wang';
my $type_new = 'GPU-SMP-Wang+Simon';
my $threads = $config{$type_new}{'threads_per_pe'};

for my $numparticles (@size) {
	for my $t (@theta) {
		for my $b ( @{ $config{$type_new}{'bucketsize'} } ) {
			
			move("$base_dir/$type_old", "$base_dir/$type_new");
			
			my $dir    = "$base_dir/$type_new/$numparticles/$threads/$t/$b";
			my $prefix_old = "$type_old+$numparticles+$threads+$t+$b";
			my $prefix_new = "$type_new+$numparticles+$threads+$t+$b";
					
			for my $suffix ('out.log', 'param') {
				move("$dir/$prefix_old.$suffix", "$dir/$prefix_new.$suffix");
			}
			
			$dir .= "/acc";
			for my $suffix ('acc.out.log', 'param', 'acc') {
				move("$dir/$prefix_old.$suffix", "$dir/$prefix_new.$suffix");
			}
}}}
