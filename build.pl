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
use Benchmark qw(timediff :hireswallclock);

# TODO: allow builds w/o CUDA
my %args = (
	'prefix' 		=> cwd(),
	'charm-dir'		=> undef,
	'changa-dir'	=> undef,
	'log-file'      => undef,
	'build-dir'		=> undef,
	'charm-target' 	=> 'netlrts-linux-x86_64',
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

pod2usage( -exitval => 0, -verbose => 99 ) if $args{'help'};

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

# Save a backup if the log file already exists
move($args{'log-file'}, "$args{'log-file'}.bak") if -e $args{'log-file'};
open my $fdLog, '>', $args{'log-file'} or die "Unable to open $args{'log-file'}: $!\n";

my %build_times = (
	'charm' => [],
	'changa' => []
);

sub build_charm($) {
	my $opts = shift;
	my $cmd = "./build ChaNGa $args{'charm-target'} $args{'charm-options'} $opts --with-production --enable-lbuserdata -j$args{'njobs'}";
	print $fdLog "Building charm++ using '$cmd'... ";
	execute("
		cd $args{'charm-dir'}
		rm -rf bin include lib lib_so tmp VERSION $args{'charm-target'}*
	");
	my $begin = Benchmark->new();
	my $res = execute("
		cd $args{'charm-dir'}
		export CUDA_DIR=$args{'cuda-dir'}

		# Fix for RCA module issues (https://charm.cs.illinois.edu/redmine/issues/534)
		export PE_PKGCONFIG_LIBS=cray-rca:\$PE_PKGCONFIG_LIBS
	
		$cmd
	");
	if (!$res) {
		print $fdLog "FAILED\n";
		exit if $args{'fatal-errors'};
	} else {
		push @{$build_times{'charm'}}, timediff(Benchmark->new(), $begin)->real;
		print $fdLog "OK\n";
	}
}
sub build_changa($) {
	my $opts = shift;
	print $fdLog "Building ChaNGa using '$opts'... ";
	if( -e "$args{'changa-dir'}/Makefile") {
		execute("
			cd $args{'changa-dir'}
			make clean
			rm -f Makefile.dep
		");
	}
	my $begin = Benchmark->new();
	my $res = execute("
		cd $args{'changa-dir'}
		export CHARM_DIR=\"$args{'charm-dir'}\"
		./configure $opts
		make depends
		make -j$args{'njobs'}
	");
	if (!$res) {
		print $fdLog "FAILED\n";
		exit if $args{'fatal-errors'};
	} else {
		push @{$build_times{'changa'}}, timediff(Benchmark->new(), $begin)->real;
		print $fdLog "OK\n";
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
	$ChaNGa::Build::cooling = Configure::Option::Enable->new('cooling', ('no','cosmo'));
	make_path($args{'build-dir'}) if ! -d $args{'build-dir'};
	
	for my $smp (@$Charm::Build::smp) {
		build_charm($smp->value);
	for my $o (@{get_release_options()}) {
		build_changa(@$o);
		my $suffix = join('_', map {$_->key} ($smp, @$o));
		copy("$args{'changa-dir'}/ChaNGa", "$args{'build-dir'}/ChaNGa_$suffix") or die "Copy failed: $!";
	}}
}

sub mean {
	use List::Util qw(sum);
	return 0.0 if @{$_[0]} <= 0;
	sum(@{$_[0]}) / @{$_[0]};
}
sub stddev {
	use List::Util qw(sum);
	my ($mean, $data) = @_;
	return 0.0 if @$data <= 1; 
	sqrt(sum(map {($_-$mean)**2.0} @$data) / (@$data - 1));
}

# Display build statistics
print $fdLog "\n\n", '*'x10, " Build statistics ", '*'x10, "\n";
for my $type (keys %build_times) {
	print $fdLog "Built ", scalar @{$build_times{$type}}, " versions of $type.\n";
	my $avg = mean($build_times{$type});
	my $std = stddev($avg, $build_times{$type});
	printf($fdLog "    time: %.3f +- %.3f seconds\n", $avg, $std);
}

{
	my $build_file = 'build.timings';
	move($build_file, "$build_file.bak") if -e $build_file;
	open my $fdOut, '>', $build_file or die;
	for my $type (keys %build_times) {
		print $fdOut "$type: ", join(',', @{$build_times{$type}}), "\n";
	}
}


__END__

=head1 DESCRIPTION

A tool for automating building Charm++ and ChaNGa
 
=head1 SYNOPSIS
 
build [options]
 
 Options:
   --prefix             Base directory for the source and build directories (default: pwd)
   --charm-dir=PATH     Charm directory (default: prefix/charm)
   --changa-dir=PATH    ChaNGa directory (default: prefix/changa)
   --log-file=FILE      Store logging data in FILE (default: prefix/build.log)
   --build-dir          Directory where outputs are stored (default: prefix/build)
   --charm-target=T     Build charm++ for target T (default: netlrts-linux-x86_64)
   --charm-options=S    Pass options S to charm build (wrap S in quotes to pass many values)
   --cuda-dir           Override CUDA toolkit directory
   --force-test         Build executables for performing force accuracy tests (default: no)
   --release            Run complete set of build tests for ChaNGa release (default: no)
   --basic              Run only basic set of build tests (default: yes)
   --njobs=N            Number of make jobs (default: N=2)
   --[no-]fatal-errors  Kill build sequence on any error (default: no; errors are reported only)
   --help               Print this help message

=cut
