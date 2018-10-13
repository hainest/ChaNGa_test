use strict;
use warnings;
use Cwd qw(cwd);
use lib cwd();
use Getopt::Long qw(GetOptions);
use File::Copy qw(copy move);
use File::Path qw(make_path);
use Configure;
use ChaNGa;
use ChaNGa::Util qw(execute any);
use ChaNGa::Build qw(:all);
use Cwd qw(cwd);
use Pod::Usage;
use Benchmark qw(timediff :hireswallclock);
use Digest::MD5 qw(md5_base64);
use Try::Tiny;

my %args = (
	'prefix' 		=> cwd(),
	'charm-dir'		=> undef,
	'changa-dir'	=> undef,
	'log-file'      => undef,
	'build-dir'		=> undef,
	'charm-target' 	=> 'netlrts-linux-x86_64',
	'charm-options' => '',	# This needs to be an empty string _NOT_ undef
	'cuda-dir'		=> '',	# This needs to be an empty string _NOT_ undef
	'build-type'	=> 'default',
	'cuda'			=> 1,
	'smp'			=> 0,
	'projections'   => 0,
	'njobs' 		=> 2,
	'fatal-errors'	=> 0,
	'charm'			=> 1,
	'changa'		=> 1,
	'help' 			=> 0
);
GetOptions(\%args,
	'prefix=s', 'charm-dir=s', 'changa-dir=s', 'log-file=s',
	'build-dir=s', 'charm-target=s', 'charm-options=s',
	'cuda-dir=s', 'build-type=s', 'cuda!', 'smp!',
	'projections!', 'njobs=i', 'fatal-errors!',
	'save-binaries!', 'charm!', 'changa!', 'help'
) or pod2usage(2);
pod2usage( -exitval => 0, -verbose => 99 ) if $args{'help'};

$args{'changa-dir'} //= "$args{'prefix'}/changa";
$args{'charm-dir'} //= "$args{'prefix'}/charm";
$args{'build-dir'} //= "$args{'prefix'}/build";
$args{'log-file'} //= "$args{'prefix'}/build.log";

# Sanity check
die "Must build at least one configuration\n" if !$args{'charm'} && !$args{'changa'};

# Save a backup if the log file already exists
move($args{'log-file'}, "$args{'log-file'}.bak") if -e $args{'log-file'};
open my $fdLog, '>', $args{'log-file'} or die "Unable to open $args{'log-file'}: $!\n";

# Create the build directory
make_path($args{'build-dir'});

sub build_charm {
	my ($fdLog, $dest, $opts) = @_;
	print $fdLog "Building charm++ using '$opts'... ";
	make_path($dest);

	my $begin = Benchmark->new();
	my $res = execute("
		cd $dest
		export CUDA_DIR=$args{'cuda-dir'}

		cd $dest
		$args{'charm-dir'}/build ChaNGa $args{'charm-target'} $args{'charm-options'} $opts \\
		--with-production --enable-lbuserdata -j$args{'njobs'} 1>build.out 2>build.err
	");
	if (!$res) {
		print $fdLog "FAILED\n";
		die if $args{'fatal-errors'};
	}
	print $fdLog "OK\n";
	return timediff(Benchmark->new(), $begin)->real;
}
sub build_changa {
	my ($fdLog, $charm_src, $dest, $opts) = @_;
	print $fdLog "Building ChaNGa using '$opts -j$args{'njobs'}'... ";
	make_path($dest);

	my $begin = Benchmark->new();
	my $res = execute("
		cd $dest
		export CHARM_DIR=\"$charm_src\"
		$args{'changa-dir'}/configure $opts 1>config.out 2>config.err
		make -j$args{'njobs'} 1>build.out 2>build.err
	");
	if (!$res) {
		print $fdLog "FAILED\n" and die;
	}
	print $fdLog "OK\n";
	return timediff(Benchmark->new(), $begin)->real;
}

sub do_charm_build {
	my ($fdLog, $config) = @_;
	my @build_times;
	for my $src_dir (keys %{$config}) {
		my $dest = "$args{'build-dir'}/charm/$src_dir";
		my $cur = $config->{$src_dir};
		my $switches = (ref $cur eq ref []) ? join(' ', @{$cur}) : $cur;
		try {
			push @build_times, build_charm($fdLog, $dest, $switches);
		} catch {
			die if $args{'fatal-errors'};
		}
	}
	return @build_times;
}

sub do_changa_build {
	my ($fdLog, $config) = @_;
	my @build_times;
	for my $src_dir (keys %{$config}) {
		my $dest = "$args{'build-dir'}/changa/$src_dir";
		my $cur = $config->{$src_dir};
		my $switches = (ref $cur eq ref []) ? join(' ', @{$cur}) : $cur;

		my $is_cuda = $src_dir =~ /cuda/;
		my $is_smp  = $src_dir =~ /smp/;
		my $is_proj = $src_dir =~ /projections/;

		my $changa_opts = ChaNGa::Build::get_options($args{'build-type'});
		while (my $changa = $changa_opts->()) {
			push @{$changa}, "--with-cuda=$args{'cuda-dir'}" if $is_cuda;
			push @{$changa}, "--enable-projections" if $is_proj;
			my $id = md5_base64(localtime . "@$changa");
			$id =~ s|/|_|g;
			my $dest = "$args{'build-dir'}/changa/$id";
			try {
				my $time = build_changa($fdLog, "$args{'build-dir'}/charm/$src_dir", $dest, "@$changa");
				push @build_times, $time;
			} catch {
				die if $args{'fatal-errors'};
			}
		}
	}
	return @build_times;
}

sub display_stats {
	my ($fdLog, $build_times) = @_;

	# Display build statistics in log file
	print $fdLog "\n\n", '*'x10, " Build statistics ", '*'x10, "\n";
	for my $type (keys %{$build_times}) {
		print $fdLog "Built ", scalar @{$build_times->{$type}}, " versions of $type.\n";
		use ChaNGa::Util qw(mean stddev);
		my $avg = mean($build_times->{$type});
		my $std = stddev($avg, $build_times->{$type});
		printf($fdLog "    time: %.3f +- %.3f seconds\n", $avg, $std);
	}

	# Save individual timings to a separate file
	my $build_file = 'build.timings';
	move($build_file, "$build_file.bak") if -e $build_file;
	open my $fdOut, '>', $build_file or die "Unable to open $build_file: $!\n";
	for my $type (keys %{$build_times}) {
		print $fdOut "$type: ", join(',', @{$build_times->{$type}}), "\n";
	}
}

sub print_log {
	print $fdLog $_[0], "\n";
}

#----------------------------------------------------------------------------------------

my $log_string;
open my $log, '>', \$log_string;
print $log "Start time: ", scalar localtime, "\n";

my @charm_opts = grep {$args{$_} == 1} keys %{Charm::Build::Opts::get_opts()};
my %charm_config = Charm::Build::get_config(@charm_opts);

my %build_times = (
	'charm' => [],
	'changa' => []
);

# Build all the versions of Charm++
if ($args{'charm'}) {
	try {
		@{$build_times{'charm'}} = do_charm_build($log, \%charm_config);
	} catch {
		print_log($log_string) and die;
	}
}

# Build all the versions of ChaNGa
if ($args{'changa'}) {
	try {
		@{$build_times{'changa'}} = do_changa_build($log, \%charm_config);
	} catch {
		print_log($log_string) and die;
	}
}

print $log "End time: ", scalar localtime, "\n";

display_stats($log, \%build_times);

print_log($log_string);

__END__

=head1 DESCRIPTION

A tool for automating building Charm++ and ChaNGa

=head1 SYNOPSIS

build [options]

 Options:
   --prefix             Base directory for the source and build directories (default: pwd)
   --charm-dir=PATH     Charm source directory (default: prefix/charm)
   --changa-dir=PATH    ChaNGa source directory (default: prefix/changa)
   --log-file=FILE      Store logging data in FILE (default: prefix/build.log)
   --build-dir          Directory where outputs are stored (default: prefix/build)
   --charm-target=T     Build charm++ for target T (default: netlrts-linux-x86_64)
   --charm-options=S    Pass options S to charm build (wrap S in quotes to pass many values)
   --cuda-dir           Override CUDA toolkit directory
   --build-type         Type of build test to perform (default, basic, force-test, release)
   --[no-]cuda          Enable CUDA tests (default: yes)
   --[no-]smp           Enable SMP tests (default: no)
   --[no-]projections   Enable Projections tests (default: no)
   --njobs=N            Number of make jobs (default: N=2)
   --[no-]fatal-errors  Kill build sequence on any error (default: no; errors are reported only)
   --[no-]charm         Build the Charm++ libraries for ChaNGa (default: yes)
   --[no-]changa        Build ChaNGa (default: yes)
   --help               Print this help message

=head1 NOTES

In addition to the predefined build types (default, basic, force-test, and release), you can specify a
comma-separated list of configure targets to build. For example,

	build.pl --build-type=hexadecapole,float

will test the HEXADECAPOLE and COSMO_FLOAT options (note: CUDA is still enabled here; to disable, use --no-cuda).

=cut
