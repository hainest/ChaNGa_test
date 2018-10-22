use strict;
use warnings;
use Cwd qw(cwd);
use lib cwd();
use Getopt::Long qw(GetOptions);
use File::Copy qw(copy move);
use File::Path qw(make_path);
use ChaNGa;
use ChaNGa::Util qw(execute any);
use ChaNGa::Build qw(:all);
use Pod::Usage;
use Benchmark qw(timediff :hireswallclock);
use Try::Tiny;
use lib cwd().'/MPI';
use MPI::Simple;

# Set up MPI
MPI::Simple::Init();
my $mpi_rank = MPI::Simple::Comm_rank();
my $mpi_size = MPI::Simple::Comm_size();

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
	'charm'			=> 1,
	'changa'		=> 1,
	'debug'			=> 1,
	'help' 			=> 0
);

{
	my $res = GetOptions(\%args,
		'prefix=s', 'charm-dir=s', 'changa-dir=s', 'log-file=s',
		'build-dir=s', 'charm-target=s', 'charm-options=s',
		'cuda-dir=s', 'build-type=s', 'cuda!', 'smp!',
		'projections!', 'njobs=i', 'charm!', 'changa!', 'debug!',
		'help'
	);
	
	if(!$res) {
		pod2usage(2) if $mpi_rank == 0;
		MPI::Simple::Die_sync();
	}
}

if($args{'help'}) {
	pod2usage(-exitval => 0, -verbose => 99) if $mpi_rank == 0;
	MPI::Simple::Die_sync();
}

# Sanity check
if(!$args{'charm'} && !$args{'changa'}) {
	print STDERR "Must build at least one configuration\n" if $mpi_rank == 0;
	MPI::Simple::Die_sync();
}

# Default directory and file locations
$args{'changa-dir'} //= "$args{'prefix'}/changa";
$args{'charm-dir'} //= "$args{'prefix'}/charm";
$args{'build-dir'} //= "$args{'prefix'}/build";
$args{'log-file'} //= "$args{'prefix'}/build.log";

if ($mpi_rank == 0) {
	# Save a backup, if the log file already exists
	move($args{'log-file'}, "$args{'log-file'}.bak") if -e $args{'log-file'};

	# Create the build directory
	make_path($args{'build-dir'});
}

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
		print $fdLog "FAILED\n" and die;
	}
	print $fdLog "OK\n";
	return timediff(Benchmark->new(), $begin)->real;
}
sub build_changa {
	my ($fdLog, $charm_src, $id, $debug, $opts) = @_;
	print $fdLog "Building ChaNGa($id) using '$debug $opts -j$args{'njobs'}'... ";
	
	my $dest = "$args{'build-dir'}/changa/$id";
	make_path($dest);
	
	use ChaNGa::Util qw(copy_dir);
	copy_dir("$args{'changa-dir'}/../utility/structures", "$dest/structures");

	my $begin = Benchmark->new();
	my $res = execute("
		cd $dest
		export CHARM_DIR=\"$charm_src\"
		$args{'changa-dir'}/configure STRUCT_DIR=structures $opts 1>config.out 2>config.err
		make $debug -j$args{'njobs'} 1>build.out 2>build.err
	");
	if (!$res) {
		print $fdLog "FAILED\n" and die;
	}
	print $fdLog "OK\n";
	return timediff(Benchmark->new(), $begin)->real;
}
sub write_log {
	my $data = shift;
	
	if($mpi_rank == 0) {
		my %logs = (
			'0' => $data
		);
		
		my $sender = 0;
		while(scalar keys %logs != $mpi_size) {
			my $log = MPI::Simple::Recv('any', 0, \$sender);
			$logs{$sender} = $log;
		}
		
		open my $fdLog, '>>', $args{'log-file'};
		for my $id (sort keys %logs) {
			print $fdLog $logs{$id};
		}
	} else {
		MPI::Simple::Send($data, 0, 0);
	}
}
#----------------------------------------------------------------------------------------

my $log_string;
open my $log, '>', \$log_string;

my %build_times = ('charm'=>[],'changa'=>[]);

if($args{'charm'}) {
	my $config;
	if($mpi_rank == 0) {
		my @charm_opts = grep {$args{$_} == 1} keys %{Charm::Build::Opts::get_opts()};
		$config = Charm::Build::get_config(@charm_opts);
		
		if($mpi_size > 1) {
			# Assign configurations to each rank in a round-robin fashion
			my @all_configs = %{$config};
			my @configs_per_rank = ((undef) x $mpi_size);
			my $cur_id = 0;
			while(my @cur = splice(@all_configs, 0, 2)) {
				push @{$configs_per_rank[$cur_id]}, @cur;
				$cur_id = ++$cur_id % $mpi_size;
			}
			
			# Rank 0 gets nothing if there are fewer configurations
			# than MPI ranks. Otherwise, it gets the last one
			# so that that it doesn't get the possible extra config.
			# This guarantees it does either no work or the same amount of work
			# as the other ranks, but never does the maximum amount of work.
			my $tmp = pop @configs_per_rank;
			$config = $tmp ? {@{$tmp}} : {};
			
			$cur_id = 1;
			for my $c (@configs_per_rank) {
				MPI::Simple::Send($c ? {@{$c}} : {}, $cur_id++, 0);
			}
		}
	} else {
		$config = MPI::Simple::Recv(0, 0);
	}

	# Do the builds
	my $error = 0;
	for my $src_dir (keys %{$config}) {
		my $dest = "$args{'build-dir'}/charm/$src_dir";
		my $cur = $config->{$src_dir};
		my $switches = (ref $cur eq ref []) ? join(' ', @{$cur}) : $cur;
		try {
			push @{$build_times{'charm'}}, build_charm($log, $dest, $switches);
		} catch {
			$error = 1;
		};
	}
	
	MPI::Simple::Barrier();
	write_log($log_string);
	$log_string = undef;

	# If any rank had an error, we can't continue
	MPI::Simple::Die_sync() if MPI::Simple::Error($error);
}

if ($args{'changa'}) {
	my $changa_config;
	if($mpi_rank == 0) {
		my @charm_opts = grep {$args{$_} == 1} keys %{Charm::Build::Opts::get_opts()};
		my $charm_config = Charm::Build::get_config(@charm_opts);
		$changa_config = ChaNGa::Build::get_config($args{'build-type'}, $charm_config, $args{'cuda-dir'});
		my @configs_per_rank = ((undef) x $mpi_size);

		if($mpi_size > 1) {
			# Assign configurations to each rank in a round-robin fashion
			my $rank = 0;
			for my $c (@{$changa_config}) {
				push @{$configs_per_rank[$rank]}, $c;
				$rank = ++$rank % $mpi_size;
			}
			
			# Rank 0 gets nothing if there are fewer configurations
			# than MPI ranks. Otherwise, it gets the last one
			# so that that it doesn't get the possible extra config.
			# This guarantees it does either no work or the same amount of work
			# as the other ranks, but never does the maximum amount of work.
			my $tmp = pop @configs_per_rank;
			$changa_config = $tmp || [];
			
			$rank = 1;
			for my $c (@configs_per_rank) {
				MPI::Simple::Send($c || [], $rank++, 0);
			}
		}
	} else {
		$changa_config = MPI::Simple::Recv(0, 0);
	}

	# Do the builds
	my @debug_flags = $args{'debug'} ? ('DEBUG=1','DEBUG=0') : ('');
	for my $c (@{$changa_config}) {
		my ($charm_src, $opts) = @{$c}{'charm_src','opts'};
		
		for my $debug (@debug_flags) {
			use Digest::MD5 qw(md5_base64);
			my $id = md5_base64(localtime . "$debug @$opts");
			$id =~ s|/|_|g;
			
			try {
				my $time = build_changa($log, "$args{'build-dir'}/charm/$charm_src", $id, $debug, "@$opts");
				push @{$build_times{'changa'}}, $time;
			} catch {
				# If there is an error, it will be reported in the log.
				# We can continue without issue.
			}
		}
	}

	MPI::Simple::Barrier();
	write_log($log_string);
	$log_string = undef;
}

if($mpi_rank == 0){
	# Collect the build times from the other ranks
	if($mpi_size > 1) {
		my $count = 1; # Don't include rank 0
		while($count++ < $mpi_size) {
			my $times = MPI::Simple::Recv('any', 0);
			for my $type ('changa', 'charm') {
				if(scalar @{$times->{$type}} > 0) {
					push @{$build_times{$type}}, @{$times->{$type}};
				}
			}
		}
	}
	
	open my $fdLog, '>>', $args{'log-file'};
	
	# Display build statistics in log file
	print $fdLog "\n\n", '*'x10, " Build statistics ", '*'x10, "\n";
	for my $type (keys %build_times) {
		print $fdLog "Built ", scalar @{$build_times{$type}}, " versions of $type.\n";
		use ChaNGa::Util qw(mean stddev);
		my $avg = mean($build_times{$type});
		my $std = stddev($avg, $build_times{$type});
		printf($fdLog "    time: %.3f +- %.3f seconds\n", $avg, $std);
	}

	# Save individual timings to a separate file
	my $build_file = 'build.timings';
	move($build_file, "$build_file.bak") if -e $build_file;
	open my $fdOut, '>', $build_file or die "Unable to open $build_file: $!\n";
	for my $type (keys %build_times) {
		print $fdOut "$type: ", join(',', @{$build_times{$type}}), "\n";
	}
} else {
	MPI::Simple::Send(\%build_times, 0, 0);
}

MPI::Simple::Finalize();

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
   --[no-]charm         Build the Charm++ libraries for ChaNGa (default: yes)
   --[no-]changa        Build ChaNGa (default: yes)
   --[no-]debug         Include debug build of ChaNGa in tests (default: yes)
   --help               Print this help message

=head1 NOTES

In addition to the predefined build types (default, basic, force-test, and release), you can specify a
comma-separated list of configure targets to build. For example,

	build.pl --build-type=hexadecapole,float

will test the HEXADECAPOLE and COSMO_FLOAT options (note: CUDA is still enabled here; to disable, use --no-cuda).

=cut
