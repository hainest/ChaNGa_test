use strict;
use warnings;
use ChaNGa qw(%config @theta %size_decode @size);
use PDL;
use PDL::NiceSlice;

my $base_dir        = 'results/';
my $theta           = pdl( \@theta );
my @types           = sort keys %config;
my $timings         = zeros( scalar @types, scalar @theta );
my $timings_gravity = zeros( dims($timings) );

for my $i ( 0 .. @types - 1 ) {
	my $type    = $types[$i];
	for my $threads ($config{$type}{'threads_per_pe'}) {
	for my $numparticles (@size) {
		my @times = ();
		for my $j ( 0 .. @theta - 1 ) {
			my $t = $theta[$j];
			for my $b ( @{ $config{$type}{'bucketsize'} } ) {
				my $dir    = "$base_dir/$type/$numparticles/$threads/$t/$b";
				my $prefix = "$type+$numparticles+$threads+$t+$b";
				my $file   = "$dir/$prefix.out.log";
				my $data   = rcols( $file, [12] );
				$timings ( $i, $j ) .= avg( $data ( 1 : ) );

				open my $fdIn, '<', "$dir/stdout" or die "Unable to open $dir/stdout: $!\n";
				while (<$fdIn>) {
					next unless /Calculating gravity and SPH took (.+?) seconds/;
					push @times, $1;
				}
			}
			$timings_gravity ( $i, $j ) .= avg( pdl( \@times ) );
			@times = ();
		}
	}
}}

open my $fdOut, '>', 'timings.csv';
print $fdOut '# theta: ', join( ',', @theta ), "\n";
for my $i ( 0 .. @types - 1 ) {
	print $fdOut join( ',', $types[$i], $timings ( ($i), : )->dog ), "\n";
}

open $fdOut, '>', 'timings_gravity.csv';
print $fdOut '# theta: ', join( ',', @theta ), "\n";
for my $i ( 0 .. @types - 1 ) {
	print $fdOut join( ',', $types[$i], $timings_gravity ( ($i), : )->dog ), "\n";
}
