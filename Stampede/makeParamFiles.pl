use strict;
use warnings;
use File::Path qw(make_path);
use Cwd qw(cwd);
use ChaNGa qw(%config $base_dir);

my $simTime        = 0.005;                      # 5 Myrs
my $maxStep        = 0.001;                      # 1 Myr
my $nSteps         = int($simTime / $maxStep);

for my $type (keys %config) {
	for my $numparticles (keys %{$config{$type}}) {
		for my $threads (@{$config{$type}{$numparticles}{'threads_per_node'}}) {
			for my $theta ('0.1', '0.3', '0.5', '0.7', '0.9') {
				for my $b (@{$config{$type}{$numparticles}{'bucketsize'}}) {

					my $dir = "$base_dir/$type/$numparticles/$threads/$theta/$b";
					my $suffix = "$type+$numparticles+$threads+$theta+$b";
					make_path "$dir/acc" if (!-d "$dir/acc");

					open my $fdOut, '>', "$dir/testdisk.param" or die "Unable to create $dir/testdisk.param: $!\n";
					print $fdOut <<EOF
nSteps          = $nSteps
dDelta          = $maxStep
dTheta          = 0.5
iOutInterval    = 100
achOutName      = $dir/testdisk.$suffix
iLogInterval	= 1
dEta			= 0.15491
achInFile		= $base_dir/testdisk.${numparticles}.tipsy
bDoDensity		= 0
bPrefetch		= 1
nBucket         = $b
EOF
					  ;

					close $fdOut;
					open $fdOut, '>', "$dir/acc/testdisk.param" or die;
					print $fdOut <<EOF
nSteps          = 0
dDelta          = $maxStep
dTheta          = $theta
iOutInterval    = $nSteps
achOutName      = $dir/acc/testdisk.$suffix
iLogInterval	= 1
dEta			= 0.15491
achInFile		= $dir/testdisk.$suffix
bDoDensity		= 0
bPrefetch		= 1
EOF
					  ;
				}
			}
		}
	}
}
