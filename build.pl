use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use File::Path qw(make_path);
use File::Copy qw(copy move);
use Configure;
use ChaNGa;
use ChaNGa::Util qw(execute);
use ChaNGa::Build qw(:all);
use Cwd qw(cwd);
use Pod::Usage;

# TODO: allow builds w/o CUDA
my %args = (
	'prefix' 		=> cwd(),
	'charm-dir'		=> undef,
	'changa-dir'	=> undef,
	'log-file'      => undef,
	'build-dir'		=> undef,
	'charm-target' 	=> 'net-linux-x86_64',
	'charm-options' => '',	# This needs to be an empty string _NOT_ undef
	'cuda-dir'		=> '',	# This needs to be an empty string _NOT_ undef
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

$args{'changa-dir'} //= "$args{'prefix'}/changa";
$args{'charm-dir'} //= "$args{'prefix'}/charm";
$args{'build-dir'} //= "$args{'prefix'}/build";
$args{'log-file'} //= "$args{'prefix'}/build.log";

# Only allow one test type to be specified
if (($args{'basic'} + $args{'force-test'} + $args{'release'}) > 1) {
	pod2usage("$0: Too many build types specified\n");
}

# By default, use the 'basic' test type
$args{'basic'} = int(!($args{'force-test'} || $args{'release'}));

# Override the default CUDA flag
if ($args{'cuda-dir'}) {
	$ChaNGa::Build::cuda = Configure::Option::With->new('cuda', ($args{'cuda-dir'}, 'no'));
}

open my $fdLog, '>', $args{'log-file'} or die "Unable to open $args{'log-file'}: $!\n";

sub build_charm($) {
	my $opts = shift;
	my $export = ($args{'cuda-dir'} ne '') ? "export CUDA_DIR=$args{'cuda-dir'}" : '';
	my $cmd = "./build ChaNGa $args{'charm-target'} $args{'charm-options'} $opts --with-production --enable-lbuserdata -j$args{'njobs'}";
	print $fdLog "Building charm++ using '$cmd'... ";
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
		die "charm build FAILED using '$cmd'\n" if $args{'fatal-errors'};
		print $fdLog "FAILED\n";
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
		die "ChaNGa build FAILED using '$opts'\n" if $args{'fatal-errors'};
		print $fdLog "FAILED\n";
	}
}

if ($args{'basic'}) {
	for my $cuda (get_cuda_options()) {
		build_charm($cuda->{'charm'}->value);
	for my $o (@{get_basic_options()}) {
		my $opts = join(' ', map {$_->value} ($cuda->{'changa'}, @$o));
		build_changa($opts);
	}}
} elsif ($args{'force-test'}) {
	make_path($args{'build-dir'}) if ! -d $args{'build-dir'};
	
	for my $cuda (get_cuda_options()) {
	for my $smp (@$Charm::Build::smp) {
		build_charm(join(' ', $cuda->{'charm'}->value, $smp->value));
	for my $o (@{get_forcetest_options()}) {
		my $opts = join(' ', map {$_->value} ($cuda->{'changa'}, @$o));
		build_changa($opts);
		my $suffix = join('_', map {$_->key} (($cuda->{'changa'}, $smp, @$o)));
		copy("$args{'changa-dir'}/ChaNGa", "$args{'build-dir'}/ChaNGa_$suffix") or die "Copy failed: $!";
	}}}
} elsif ($args{'release'}) {
	for my $cuda (get_cuda_options()) {
	for my $smp (@$Charm::Build::smp) {
		build_charm(join(' ', $cuda->{'charm'}->value, $smp->value));
	for my $o(@{get_release_options()}) {
		my $opts = join(' ', map {$_->value} ($cuda->{'changa'}, @$o));
		build_changa($opts);
	}}}
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

