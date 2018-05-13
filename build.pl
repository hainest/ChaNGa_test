use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use File::Copy qw(copy move);
use File::Path qw(make_path);
use Configure;
use ChaNGa;
use ChaNGa::Util qw(execute);
use ChaNGa::Build qw(:all);
use Cwd qw(cwd);
use Pod::Usage;
use Benchmark qw(timediff :hireswallclock);

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
	'save-binaries' => 0,
	'charm'			=> 1,
	'help' 			=> 0
);
GetOptions(\%args,
	'prefix=s', 'charm-dir=s', 'changa-dir=s', 'log-file=s',
	'build-dir=s', 'charm-target=s', 'charm-options=s',
	'cuda-dir=s', 'build-type=s', 'cuda!', 'smp!',
	'projections!', 'njobs=i', 'fatal-errors!',
	'save-binaries!', 'charm!', 'help'
) or pod2usage(2);
pod2usage( -exitval => 0, -verbose => 99 ) if $args{'help'};

$args{'changa-dir'} //= "$args{'prefix'}/changa";
$args{'charm-dir'} //= "$args{'prefix'}/charm";
$args{'build-dir'} //= "$args{'prefix'}/build";
$args{'log-file'} //= "$args{'prefix'}/build.log";

# Save a backup if the log file already exists
move($args{'log-file'}, "$args{'log-file'}.bak") if -e $args{'log-file'};
open my $fdLog, '>', $args{'log-file'} or die "Unable to open $args{'log-file'}: $!\n";

# Create the build directory
make_path($args{'build-dir'});

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
	print $fdLog "Building ChaNGa using '$opts -j$args{'njobs'}'... ";
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

print $fdLog "Start time: ", scalar localtime, "\n";
my $charm_opts = Charm::Build::get_options(map {$_ => $args{$_}} ('cuda','smp','projections'));
while (my $charm = $charm_opts->()) {
	build_charm("@$charm") if $args{'charm'};
	
	use List::Util qw(any);
	my $is_cuda = any {$_ eq 'cuda' } @$charm;
	my $is_smp  = any {$_ eq 'smp' } @$charm;
	my $is_proj = any {$_ eq '--enable-tracing=yes' } @$charm;

	my $changa_opts = ChaNGa::Build::get_options($args{'build-type'});
	while (my $changa = $changa_opts->()) {
		push @{$changa}, "--with-cuda=$args{'cuda-dir'}" if $is_cuda;
		push @{$changa}, "--enable-projections" if $is_proj;
		build_changa("@$changa");
		
		if($args{'save-binaries'}) {
			my $suffix = '';
			$suffix .= '_cuda' if $is_cuda;
			$suffix .= '_proj' if $is_proj;
			$suffix .= '_smp'  if $is_smp;
			$suffix .= ChaNGa::Build::Opts::make_short_name("@$changa");
			my $src = "$args{'changa-dir'}/ChaNGa";
			my $dst = "$args{'build-dir'}/ChaNGa$suffix";
			copy($src, $dst) or die "copying '$src' to '$dst' failed: $!\n";
			chmod 0755, $dst;
			$src = "$args{'changa-dir'}/charmrun";
			$dst = "$args{'build-dir'}/charmrun$suffix"; 
			copy($src, $dst) or die "copying '$src' to '$dst' failed: $!\n";
			chmod 0755, $dst;
		}
	}
}
print $fdLog "End time: ", scalar localtime, "\n";

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
   --save-binaries      Save the ChaNGa binary generated by each build configuration (default: no)
   --[no-]charm         Build the Charm++ libraries for ChaNGa (default: yes)
   --help               Print this help message

=head1 NOTES

In addition to the predefined build types (default, basic, force-test, and release), you can specify a
comma-separated list of configure targets to build. For example,

	build.pl --build-type=hexadecapole,float
	
will test the HEXADECAPOLE and COSMO_FLOAT options (note: CUDA is still enabled here; to disable, use --no-cuda). 

=cut
