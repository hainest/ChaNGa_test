use strict;
use warnings;
use File::Path qw(mkpath);
use ChaNGa qw(%config $base_dir @theta @size);

my $simTime = 0.005;                      # 5 Myrs
my $maxStep = 0.001;                      # 1 Myr
my $nSteps  = int($simTime / $maxStep);
my $snapshot_suffix = sprintf('%06s',int($simTime*1e3));

for my $type (keys %config) {
for my $numparticles (@size) {
for my $t (@theta) {
for my $b (@{$config{$type}{'bucketsize'}}) {
for my $threads (@{$config{$type}{'threads_per_pe'}}) {
	my $dir     = "$base_dir/$type/$numparticles/$threads/$t/$b";
	my $prefix  = "$type+$numparticles+$threads+$t+$b";
	mkpath "$dir/acc" if (!-d "$dir/acc");

	open my $fdOut, '>', "$dir/${prefix}.param" or die "Unable to create $dir/${prefix}.param: $!\n";
	print $fdOut <<EOF
nSteps          = $nSteps
dDelta          = $maxStep
dTheta          = $t
iOutInterval    = $nSteps
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
achInFile		= $dir/$prefix.out.$snapshot_suffix
bDoDensity		= 0
bPrefetch		= 1
nBucket         = $b
EOF
;
	}
}}}}
