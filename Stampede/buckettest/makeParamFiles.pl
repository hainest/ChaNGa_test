use strict;
use warnings;
use File::Path qw(make_path);
use Cwd qw(cwd);
use ChaNGa qw(%config);

my $baseDir = cwd();

my $simTime = 0.005; 	# 5 Myrs
my $maxStep = 0.001; 	# 1 Myr
my $nSteps = int($simTime / $maxStep);

for my $type (keys %config) {
	for my $numparticles (keys %{$config{$type}}) {
		for my $t (@{$config{$type}{$numparticles}{'threads'}}) {
			for my $b (@{$config{$type}{$numparticles}{'bucketsize'}}) {
				
				my $dir = "$baseDir/$type/$numparticles/$t/$b";
				make_path $dir if(! -d $dir);
				
				open my $fdOut, '>', "$dir/testdisk.param" or die "Unable to create $dir/testdisk.param: $!\n";
				print $fdOut <<EOF
nSteps          = $nSteps
dDelta          = $maxStep
dTheta          = 0.5
iOutInterval    = 100
achOutName      = $dir/testdisk
iLogInterval	= 1
dEta			= 0.15491
achInFile		= $baseDir/testdisk.${numparticles}.tipsy
bDoDensity		= 0
bPrefetch		= 1
nBucket         = $b
EOF
;
			}
		}
	}
}
