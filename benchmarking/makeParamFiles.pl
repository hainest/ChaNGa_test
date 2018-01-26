use strict;
use warnings;
use Cwd qw(cwd);
use Pod::Usage qw(pod2usage);
use File::Path qw(mkpath);
use ChaNGa qw(get_all_options);
use Getopt::Long qw(GetOptions);

my %options = (
	'base_dir' 	=> cwd(),
	'eta'      	=> 0.15491,
	'acc'  		=> 1,
	'help' 		=> 0
);
GetOptions(\%options,
	'base_dir=s', 'eta=f', 'acc!', 'help'
) or pod2usage(1);

pod2usage( -exitval => 0, -verbose => 1 ) if $options{'help'};

if (@ARGV != 1) {
	print "Missing input file name\n";
	pod2usage( -exitval => 0, -verbose => 1 );
}

my $nSteps  = int($ChaNGa::sim_time / $ChaNGa::max_step);
my $snapshot_suffix = sprintf('%06s',int($ChaNGa::sim_time*1e3));

for my $o (get_all_options()) {
	my $dir = "$options{'base_dir'}/" . join('/', $o->listify);
	mkpath $dir if (!-d $dir);
	open my $fdOut, '>', "$dir/params" or die "Unable to create $dir/params: $!\n";
	&write_file($fdOut, $o, $nSteps, "$dir/out", $ARGV[0]);
	
	if ($options{'acc'}) {
		mkpath "$dir/acc" if (!-d "$dir/acc");
		open $fdOut, '>', "$dir/acc/params" or die;
		&write_file($fdOut, $o, 0, "$dir/acc/acc.out", "$dir/out.$snapshot_suffix");
	}
}

sub write_file($$$$$) {
	my ($fdOut, $o, $steps, $outfile, $infile) = @_;
	my $b = $o->bucketsize;
	my $t = $o->theta;
	
		print $fdOut <<EOF
nSteps          = $steps
dDelta          = $ChaNGa::max_step
dTheta          = $t
iOutInterval    = $nSteps
achOutName      = $outfile
iLogInterval    = 1
dEta            = $options{'eta'}
achInFile       = $infile
bDoDensity      = 0
bPrefetch       = 1
nBucket         = $b
iVerbosity      = 1
iBinaryOutput   = 1  % save outputs in SP float
EOF
;
}

__END__
 
=head1 NAME
 
Make parameter files for ChaNGa runs
 
=head1 SYNOPSIS
 
makeParamFiles.pl input.tipsy [options]
 
 Options:
   --base_dir     Directory relative to which files will be written
   --eta          Timestepping criterion (default: 0.15491)
   --[no-]acc     Output acceleration parameter files
   --help         Print this help message
=cut

