use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use ChaNGa;
use ChaNGa::Util qw(execute);
use ChaNGa::Build qw(%charm_decode);
use Cwd qw(cwd);
use Pod::Usage;

my %args = (
	'prefix' 		=> cwd(),
	'build-dir'		=> undef,
	'charm-target' 	=> 'net-linux-x86_64',
	'charm-options' => '',
	'cuda'			=> 1,
	'cuda-dir'		=> '',
	'force-test'	=> 0,
	'release'		=> 0,
	'basic'			=> 0,
	'njobs' 		=> 2,
	'fatal-errors'	=> 0,
	'help' 			=> 0
);
GetOptions(\%args,
	'prefix=s', 'build-dir=s', 'charm-target=s',
	'charm-options=s', 'cuda!', 'cuda-dir=s',
	'force-test', 'release', 'basic', 'njobs=i',
	'fatal-errors!', 'help'
) or pod2usage(2);

pod2usage( -exitval => 0, -verbose => 1 ) if $args{'help'};

my $changa_dir = "$args{'prefix'}/changa";
my $charm_dir = "$args{'prefix'}/charm";
$args{'build-dir'} = "$args{'prefix'}/build" unless $args{'build-dir'};

if (($args{'basic'} + $args{'force-test'} + $args{'release'}) > 1) {
	print "Too many build types specified\n";
	pod2usage(-exitval => 0, -verbose=>1);
}
$args{'basic'} = int(!($args{'force-test'} || $args{'release'}));

sub clean_charm() {
	execute("
		cd $charm_dir
		rm -rf bin include lib lib_so tmp VERSION $args{'charm-target'}*
	");
}
sub clean_changa() {
	if( -e "$changa_dir/Makefile") {
		execute("
			cd $changa_dir
			make dist-clean
		");
	}
}
sub build_charm($) {
	my $opts = shift;
	my $export = ($args{'cuda-dir'} ne '') ? "export CUDA_DIR=$args{'cuda-dir'}" : '';
	my $cmd = "./build ChaNGa $args{'charm-target'} $args{'charm-options'} $opts --with-production --enable-lbuserdata -j$args{'njobs'}";
	my $res = execute("
		cd $charm_dir
		$export
		$cmd
	");
	if (!$res) {
		my $msg = "\ncharm build FAILED: $cmd\n";
		die $msg if $args{'fatal-errors'};
		print STDERR $msg;
	}
}
sub build_changa($) {
	my $opts = shift;
	my $res = execute("
		cd $changa_dir
		./configure $opts
		make -j$args{'njobs'}
	");
	if (!$res) {
		my $msg = "\nChaNGa build FAILED: $opts\n";
		die $msg if $args{'fatal-errors'};
		print STDERR $msg;
	}
}

#basic: arch, hex, changesoft, bigkeys
#force-test: arch, hex, changesoft, smp, prec, simd
#release: $force-test, bigkeys, wendland, cooling
if ($args{'basic'}) {
	for my $arch ($Charm::Build::architecture->iteritems) {
		build_charm("$arch->[1]");
	for my $hex ($ChaNGa::Build::hexadecapole->values) {
	for my $cs ($ChaNGa::Build::changesoft->values) {
	for my $bg ($ChaNGa::Build::bigkeys->values) {
		my $cuda = $charm_decode{$arch->[0]};
		build_changa("$cuda $hex $cs $bg");
	}}}}
} elsif ($args{'force-test'}) {
#	copy("$changa_dir/ChaNGa", "$args{'build-dir'}/ChaNGa_$suffix");
#	my $suffix = "${type}_${smp}_${hex}_${simd}_${prec}";
} elsif ($args{'release'}) {}

__END__
 
=head1 NAME
 
charm++ and ChaNGa builder
 
=head1 SYNOPSIS
 
build [options]
 
 Options:
   --prefix             Base directory for the source and build directories (default: pwd)
   --build-dir          Directory where outputs are stored (default: prefix/build)
   --charm-target=T     Build charm++ for target T (default: net-linux-x86_64)
   --charm-options=S    Pass options S to charm build (wrap S in quotes to pass many values)
   --[no-]cuda          Enable CUDA (default: yes)
   --cuda-dir           Override CUDA toolkit directory
   --force-test         Build executables for performing force accuracy tests (default: no)
   --release            Run complete set of build tests for ChaNGa release (default: no)
   --basic              Run only basic set of build tests (default: yes)
   --njobs=N            Number of make jobs (default: N=2)
   --[no-]fatal-errors  Kill build sequence on any error (default: no; errors are reported only)
   --help               Print this help message

=cut

