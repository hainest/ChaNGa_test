use strict;
use warnings;
use Cwd qw(cwd);
use File::Path qw(make_path);
use ChaNGa qw(%config);

my $baseDir = cwd();

my $simTime        = 0.005;                        # 5 Myrs
my $maxStep        = 0.001;                        # 1 Myr
my $nSteps         = int( $simTime / $maxStep );
my $snapshotSuffix = sprintf( "%06d", $nSteps );

for my $type ( keys %config ) {
	for my $numparticles ( keys %{ $config{$type} } ) {
		for my $theta ( '0.1', '0.3', '0.5', '0.7', '0.9' ) {

			my $dir = "$baseDir/$type/$numparticles/theta$theta";
			make_path "$dir/acc" if (! -d "$dir/acc");

			open my $fdOut, '>', "$dir/testdisk.param" or die "Unable to create $dir/testdisk.param: $!\n";
			print $fdOut <<EOF
nSteps          = $nSteps
dDelta          = $maxStep
dTheta          = $theta
iOutInterval    = $nSteps
achOutName      = $dir/testdisk
iLogInterval	= 1
dEta			= 0.15491
achInFile		= $baseDir/../testdisk.$numparticles.tipsy
bDoDensity		= 0
bPrefetch		= 1
EOF
;
			close $fdOut;
			open $fdOut, '>', "$dir/acc/testdisk.param" or die;
			print $fdOut <<EOF
nSteps          = 0
dDelta          = $maxStep
dTheta          = $theta
iOutInterval    = $nSteps
achOutName      = $dir/acc/testdisk.$snapshotSuffix
iLogInterval	= 1
dEta			= 0.15491
achInFile		= $dir/testdisk.$snapshotSuffix
bDoDensity		= 0
bPrefetch		= 1
EOF
;
		}
	}
}
