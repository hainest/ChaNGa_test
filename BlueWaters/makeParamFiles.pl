use strict;
use warnings;
use File::Path qw(mkpath);
use Cwd qw(cwd);
use ChaNGa qw(%config $base_dir @theta);

my $simTime = 0.005;                      # 5 Myrs
my $maxStep = 0.001;                      # 1 Myr
my $nSteps  = int($simTime / $maxStep);

for my $type (keys %config) {
	for my $numparticles (keys %{$config{$type}}) {
		for my $pes_per_node (@{$config{$type}{$numparticles}{'pes_per_node'}}) {
			for my $threads (@{$config{$type}{$numparticles}{'threads_per_pe'}}) {
				for my $t (@theta) {
					for my $b (@{$config{$type}{$numparticles}{'bucketsize'}}) {

						my $dir    = "$base_dir/$type/$numparticles/$pes_per_node/$threads/$t/$b";
						my $prefix = "$type+$numparticles+$pes_per_node+$threads+$t+$b";
						mkpath "$dir/acc" if (!-d "$dir/acc");

						open my $fdOut, '>', "$dir/${prefix}.param"
						  or die "Unable to create $dir/${prefix}.param: $!\n";
						print $fdOut <<EOF
nSteps          = $nSteps
dDelta          = $maxStep
dTheta          = $t
iOutInterval    = 100
achOutName      = $dir/$prefix.out
iLogInterval	= 1
dEta			= 0.15491
achInFile		= $base_dir/testdisk.${numparticles}.tipsy
bDoDensity		= 0
bPrefetch		= 1
nBucket         = $b
EOF
						  ;

						close $fdOut;
						open $fdOut, '>', "$dir/acc/$prefix.param" or die;
						print $fdOut <<EOF
nSteps          = 0
dDelta          = $maxStep
dTheta          = $t
iOutInterval    = $nSteps
achOutName      = $dir/acc/$prefix.acc.out
iLogInterval	= 1
dEta			= 0.15491
achInFile		= $dir/$prefix.out
bDoDensity		= 0
bPrefetch		= 1
EOF
						  ;
					}
				}
			}
		}
	}
}
