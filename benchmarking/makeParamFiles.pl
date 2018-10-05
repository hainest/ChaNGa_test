use strict;
use warnings;
use File::Path qw(mkpath);
use Cwd qw(cwd);

my $base_dir = cwd() . '/build';

my @theta = map {$_ / 10.0} 1..7;

my $i = 1;
for my $o ('', 'cuda') {
	for my $t (@theta) {
		my $dir = "$base_dir/$i";
		mkpath $dir unless -d $dir;
		open my $fdOut, '>', "$dir/params" or die "Unable to create $dir/params: $!\n";
		$i++;
		
		print $fdOut <<EOF
nSteps          = 10
dDelta          = 0.01
dTheta          = $t
iOutInterval    = 5
achOutName      = $dir/out
iLogInterval    = 1
dEta            = 0.15491
achInFile       = $base_dir/testdisk.1M.tipsy
bDoDensity      = 0
bPrefetch       = 1
nBucket         = 32
iVerbosity      = 1
iBinaryOutput   = 1  % save outputs in SP float
EOF
;
}
}