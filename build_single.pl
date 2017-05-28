use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use Cwd qw(cwd);
use Pod::Usage;

sub execute($) {
	my $cmd = shift;
	system($cmd);
	die "\n\nError executing \n\t'$cmd'\n\n" if ( ( $? >> 8 ) != 0 || $? == -1 || ( $? & 127 ) != 0 );
}

my %simd_decode = (
	'sse2' => '--enable-sse2',
	'avx'  => '--enable-avx',
	'generic' => ''
);

my %args = (
	'prefix' 		=> cwd(),
	'with-charm'	=> undef,
	'charm-target' 	=> 'netlrts-linux-x86_64',
	'charm-options' => '',
	'with-changa'	=> '',
	'with-cuda'		=> '',
	'clean' 		=> 0,
	'smp'			=> 0,
	'float'			=> 0,
	'njobs' 		=> 2,
	'hex' 			=> 1,
	'simd' 			=> 'generic',
	'bigkeys'		=> '',
	'help' 			=> undef
);
GetOptions(\%args,
	'prefix=s', 'with-charm=s{0,1}', 'charm-target=s', 'charm-options=s',
	'with-changa=s{0,1}', 'with-cuda=s{0,1}', 'clean!', 'smp!',
	'float!', 'njobs=i', 'hex!', 'simd=s', 'bigkeys!', 'help'
) or pod2usage(2);

pod2usage( -exitval => 0, -verbose => 1 ) if $args{'help'};
if (!exists $simd_decode{$args{'simd'}}) {
	print "Unknown simd type: $args{'simd'}\n";
	pod2usage(-exitval => 0);
}

$args{'with-changa'} = $args{'prefix'} . '/changa' if (defined $args{'with-changa'} && $args{'with-changa'} eq '');
$args{'with-charm'} = $args{'prefix'} . '/charm' if (defined $args{'with-charm'} && $args{'with-charm'} eq '');
$args{'with-cuda'} = '/usr/local/lib/cuda' if (defined $args{'with-cuda'} && $args{'with-cuda'} eq '');

sub clean_charm() {
	execute("
		cd $args{'with-charm'}
		rm -rf bin include lib lib_so tmp VERSION $args{'charm-target'}*
	");
}
sub clean_changa() {
	if( -e "$args{'with-changa'}/Makefile") {
		execute("
			cd $args{'with-changa'}
			make dist-clean
		");
	}
}
if ($args{'with-charm'}) {
	clean_charm() if ($args{'clean'});
	my $cuda = ($args{'with-cuda'}) ? 'cuda' : '';
	my $smp = ($args{'smp'}) ? 'smp' : '';
	my $cuda_dir = $args{'with-cuda'} ? "export CUDA_DIR=$args{'with-cuda'}" : '';
	execute( "
		cd $args{'with-charm'}
		$cuda_dir
		./build ChaNGa $args{'charm-target'} $args{'charm-options'} $cuda $smp --with-production --enable-lbuserdata -j$args{'njobs'}
	" );
}

if ($args{'with-changa'}) {
	clean_changa() if ($args{'clean'});
	my $cuda = ($args{'with-cuda'}) ? "--with-cuda=$args{'with-cuda'}" : '';
	my $float = ($args{'float'}) ? '--enable-float' : '';
	my $hex = ($args{'hex'}) ? '' : '--disable-hexadecapole';
	my $simd = $simd_decode{$args{'simd'}};
	my $bigkeys = ($args{'bigkeys'}) ? '--enable-bigkeys' : '--disable-bigkeys';
	execute( "
		cd $args{'with-changa'}
		./configure $cuda $float $hex $simd $bigkeys
		make -j$args{'njobs'}
	" );
}

__END__

=head1 NAME
 
charm++ and ChaNGa builder
 
=head1 SYNOPSIS
 
build [options]
 
 Options:
   --prefix             Base directory for the source and build directories (default: pwd)
   --with-charm[=dir]   Build charm++ from source in dir (default dir: prefix/charm)
   --charm-target=T     Build charm++ for target T (default: netlrts-linux-x86_64)
   --charm-options=S    Pass options S to charm build (wrap S in quotes to pass many values)
   --with-changa[=dir]  Build ChaNGa from source in dir (default dir: prefix/changa)
   --with-cuda[=dir]    Enable CUDA and use library in dir (default: /usr/lib/cuda)
   --[no-]clean         Clean before building (default: no)
   --[no-]smp           Use SMP (default: no)
   --[no-]float         Use single-precision (default: no)
   --njobs=N            Number of make jobs (default: N=2)
   --[no-]hex           Use hexadecapole (default: yes)
   --simd=T             Use SIMD [T is generic, sse2, or avx] (default: generic)
   --[no-]bigkeys       Use 128-bit node keys (default: yes)
   --help               Print this help message
=cut

