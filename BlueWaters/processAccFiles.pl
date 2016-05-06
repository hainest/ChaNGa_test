use strict;
use warnings;
use ChaNGa qw(%config @theta %size_decode @size);
use PDL;
use PDL::NiceSlice;
use PDL::IO::FastRaw;

my $base_dir = 'results/';

for my $type ( keys %config ) {
	my $threads = $config{$type}{'threads_per_pe'};
	for my $numparticles (@size) {
		my $acc = zeros( $size_decode{$numparticles}, 3, scalar @theta );
		my $output_file = "$base_dir/$type/$numparticles.acc.fits";
		for my $i ( 0 .. @theta - 1 ) {
			my $t = $theta[$i];
			for my $b ( @{ $config{$type}{'bucketsize'} } ) {
				my $dir    = "$base_dir/$type/$numparticles/$threads/$t/$b/acc";
				my $prefix = "$type+$numparticles+$threads+$t+$b";
				my $input_file = "$dir/$prefix.acc.dat";

				print "Processing $input_file\n";
				$acc ( :, :, ($i) ) .= readfraw($input_file);
			}
		}
		PDL::wfits( $acc, $output_file );
	}
}
