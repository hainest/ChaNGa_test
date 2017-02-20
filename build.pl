use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use File::Path qw(make_path);
use ChaNGa;
use ChaNGa::Util qw(execute);
use ChaNGa::Build qw(get_cuda_options);
use Cwd qw(cwd);
use Pod::Usage;

# TODO: allow builds w/o CUDA
my %args = (
	'prefix' 		=> cwd(),
	'charm-dir'		=> '',
	'changa-dir'	=> '',
	'log-file'      => 'build.log',
	'build-dir'		=> undef,
	'charm-target' 	=> 'net-linux-x86_64',
	'charm-options' => '',
	'cuda-dir'		=> '',
	'force-test'	=> 0,
	'release'		=> 0,
	'basic'			=> 0,
	'njobs' 		=> 2,
	'fatal-errors'	=> 0,
	'help' 			=> 0
);
GetOptions(\%args,
	'prefix=s', 'charm-dir=s', 'changa-dir=s', 'log-file=s',
	'build-dir=s', 'charm-target=s', 'charm-options=s',
	'cuda-dir=s', 'force-test', 'release', 'basic', 'njobs=i',
	'fatal-errors!', 'help'
) or pod2usage(2);

pod2usage( -exitval => 0, -verbose => 1 ) if $args{'help'};

$args{'changa-dir'} = "$args{'prefix'}/changa" unless $args{'changa-dir'};
$args{'charm-dir'} = "$args{'prefix'}/charm" unless $args{'charm-dir'};
$args{'build-dir'} = "$args{'prefix'}/build" unless $args{'build-dir'};

if (($args{'basic'} + $args{'force-test'} + $args{'release'}) > 1) {
	print "Too many build types specified\n";
	pod2usage(-exitval => 0, -verbose=>1);
}
$args{'basic'} = int(!($args{'force-test'} || $args{'release'}));

# Override the default CUDA flag
if ($args{'cuda-dir'} ne '') {
	$ChaNGa::Build::cuda = Configure::Option::With->new('cuda', ($args{'cuda-dir'}, 'no'));
}

open my $fdLog, '>', $args{'log-file'} or die "Unable to open $args{'log-file'}: $!\n";

sub build_charm($) {
	my $opts = shift;
	my $export = ($args{'cuda-dir'} ne '') ? "export CUDA_DIR=$args{'cuda-dir'}" : '';
	my $cmd = "./build ChaNGa $args{'charm-target'} $args{'charm-options'} $opts --with-production --enable-lbuserdata -j$args{'njobs'}";
	print $fdLog "Building charm++ using $cmd\n";
	execute("
		cd $args{'charm-dir'}
		rm -rf bin include lib lib_so tmp VERSION $args{'charm-target'}*
	");
	my $res = execute("
		cd $args{'charm-dir'}
		$export
		$cmd
	");
	if (!$res) {
		my $msg = "\ncharm build FAILED: $cmd\n";
		die $msg if $args{'fatal-errors'};
		print $fdLog $msg;
	}
}
sub build_changa($) {
	my $opts = shift;
	print $fdLog "Building ChaNGa using $opts\n";
	if( -e "$args{'changa-dir'}/Makefile") {
		execute("
			cd $args{'changa-dir'}
			make dist-clean
		");
	}
	my $res = execute("
		cd $args{'changa-dir'}
		export CHARM_DIR=\"$args{'charm-dir'}\"
		./configure $opts
		make -j$args{'njobs'}
	");
	if (!$res) {
		my $msg = "\nChaNGa build FAILED: $opts\n";
		die $msg if $args{'fatal-errors'};
		print $fdLog $msg;
	}
}

if ($args{'basic'}) {
	for my $cuda (get_cuda_options()) {
		build_charm($cuda->{'charm'}->value);
	for my $hex (@$ChaNGa::Build::hexadecapole) {
	for my $cs (@$ChaNGa::Build::changesoft) {
	for my $bg (@$ChaNGa::Build::bigkeys) {
		my $opts = join(' ', map {$_->value} ($cuda->{'changa'}, $hex, $cs, $bg));
		build_changa($opts);
	}}}}
} elsif ($args{'force-test'}) {
	make_path($args{'build-dir'}) if ! -d $args{'build-dir'};
	
	for my $cuda (get_cuda_options()) {
	for my $smp (@$Charm::Build::smp) {
		build_charm(join(' ', $cuda->{'charm'}->value, $smp->value));
	for my $hex (@$ChaNGa::Build::hexadecapole) {
	for my $cs (@$ChaNGa::Build::changesoft) {
	for my $float (@$ChaNGa::Build::float) {
	for my $simd (@$ChaNGa::Build::simd) {
		my $opts = join(' ', map {$_->value} ($cuda->{'changa'}, $hex, $cs, $float, $simd));
		build_changa($opts);
		my $suffix = join('_', map {$_->key} (($cuda->{'changa'}, $smp, $hex, $cs, $float, $simd)));
		copy("$args{'changa-dir'}/ChaNGa", "$args{'build-dir'}/ChaNGa_$suffix");
	}}}}}}
} elsif ($args{'release'}) {
	for my $cuda (get_cuda_options()) {
	for my $smp (@$Charm::Build::smp) {
		build_charm(join(' ', $cuda->{'charm'}->value, $smp->value));
	for my $hex (@$ChaNGa::Build::hexadecapole) {
	for my $cs (@$ChaNGa::Build::changesoft) {
	for my $float (@$ChaNGa::Build::float) {
	for my $simd (@$ChaNGa::Build::simd) {
	for my $bk (@$ChaNGa::Build::bigkeys) {
	for my $wend (@$ChaNGa::Build::wendland) {
	for my $cool (@$ChaNGa::Build::cooling) {
		my $opts = join(' ', map {$_->value} ($cuda->{'changa'}, $hex, $cs, $float, $simd, $bk, $wend, $cool));
		build_changa($opts);
	}}}}}}}}}
}

__END__
 
=head1 NAME
 
charm++ and ChaNGa builder
 
=head1 SYNOPSIS
 
build [options]
 
 Options:
   --prefix             Base directory for the source and build directories (default: pwd)
   --charm-dir=PATH     Charm directory (default: prefix/charm)
   --changa-dir=PATH    ChaNGa directory (default: prefix/changa)
   --build-dir          Directory where outputs are stored (default: prefix/build)
   --charm-target=T     Build charm++ for target T (default: net-linux-x86_64)
   --charm-options=S    Pass options S to charm build (wrap S in quotes to pass many values)
   --cuda-dir           Override CUDA toolkit directory
   --force-test         Build executables for performing force accuracy tests (default: no)
   --release            Run complete set of build tests for ChaNGa release (default: no)
   --basic              Run only basic set of build tests (default: yes)
   --njobs=N            Number of make jobs (default: N=2)
   --[no-]fatal-errors  Kill build sequence on any error (default: no; errors are reported only)
   --help               Print this help message

=cut

