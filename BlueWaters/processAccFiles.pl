use strict;
use warnings;
use ChaNGa qw(%config @theta);
use PDL;
use PDL::NiceSlice;

my $simTime = 0.005;                      # 5 Myrs
my $snapshot_suffix = sprintf('%06s',int($simTime*1e3));
my $base_dir = 'results/';

my %size_decode = ('1M' => 1e6, '4M' => 4e6, '8M' => 8e6);

for my $type (keys %config) {
	for my $numparticles (keys %{$config{$type}}) {
		my $acc = zeros($size_decode{$numparticles},3,scalar @theta);
		for my $pes_per_node (@{$config{$type}{$numparticles}{'pes_per_node'}}) {
			for my $threads (@{$config{$type}{$numparticles}{'threads_per_pe'}}) {
				for my $t (@theta) {
					for my $b (@{$config{$type}{$numparticles}{'bucketsize'}}) {
						my $dir    = "$base_dir/$type/$numparticles/$pes_per_node/$threads/$t/$b/acc";
						my $prefix = "$type+$numparticles+$pes_per_node+$threads+$t+$b";

						open my $fdIn, '<', "$dir/$prefix.acc.out.000000.acc2" or die "Unable to open $dir/$prefix.acc.out.000000.acc2: $!\n";
						
						# Be sure to skip the header line that contains the number of particles
						$acc(:,:,(3)) .= rcols($fdIn,[],{'LINES'=>'1:-1'})->reshape($size_decode{$numparticles},3);
					}
				}
			}
		}
		PDL::wfits($acc,"$base_dir/$type/$numparticles.acc.fits");
	}
}