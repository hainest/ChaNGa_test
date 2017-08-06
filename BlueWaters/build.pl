use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use ChaNGa qw(execute);
use Cwd qw(cwd);
use Pod::Usage;

my %simd_decode = (
	'sse2' => '--enable-sse2',
	'avx'  => '--enable-avx',
	'generic' => ''
);

my %args = (
	'prefix' 	=> cwd(),
	'charm_dir' => undef,
	'changa_dir'=> undef,
	'cuda' 		=> 0,
	'charm' 	=> 1,
	'changa' 	=> 1,
	'clean' 	=> 0,
	'smp'		=> 1,
	'float' 	=> 0,
	'njobs' 	=> 2,
	'hex' 		=> 1,
	'simd' 		=> $ChaNGa::simd[0],
	'help' 		=> 0
);
GetOptions(\%args,
	'prefix=s', 'charm_dir=s', 'changa_dir=s', 'cuda!',
	'charm!', 'changa!', 'clean!', 'smp!', 'float!',
	'njobs=i', 'hex!', 'simd=s', 'help'
) or pod2usage(2);

pod2usage( -exitval => 0, -verbose => 1 ) if $args{'help'};
if (!exists $simd_decode{$args{'simd'}}) {
	print "Unknown simd type: $args{'simd'}\n";
	pod2usage(-exitval => 0);
}

$args{'changa_dir'} = $args{'prefix'} . '/changa' unless $args{'changa_dir'};
$args{'charm_dir'} = $args{'prefix'} . '/charm' unless $args{'charm_dir'};

sub clean_charm() {
	execute("
		cd $args{'charm_dir'}
		rm -rf bin include lib lib_so tmp VERSION gni-crayxe*
	");
}
sub clean_changa() {
	if( -e "$args{'changa_dir'}/Makefile") {
		execute("
			cd $args{'changa_dir'}
			make clean
		");
	}
}
if ($args{'charm'}) {
	clean_charm() if ($args{'clean'});
	my $cuda = ($args{'cuda'}) ? 'cuda' : '';
	my $smp = ($args{'smp'}) ? 'smp' : '';
	execute( "
		cd $args{'charm_dir'}
		
		# Fix for RCA module issues (https://charm.cs.illinois.edu/redmine/issues/534)
		export PE_PKGCONFIG_LIBS=cray-rca:\$PE_PKGCONFIG_LIBS
	
		export CUDA_DIR=$ENV{CRAY_CUDATOOLKIT_DIR}
		./build ChaNGa gni-crayxe hugepages $cuda $smp --with-production --enable-lbuserdata -j$args{'njobs'}
	" );
}

if ($args{'changa'}) {
	clean_changa() if ($args{'clean'});
	my $cuda = ($args{'cuda'}) ? "--with-cuda=$ENV{CRAY_CUDATOOLKIT_DIR}" : '';
	my $float = ($args{'float'}) ? '--enable-float' : '';
	my $hex = ($args{'hex'}) ? '' : '--disable-hexadecapole';
	my $simd = $simd_decode{$args{'simd'}};
	execute( "
		cd $args{'changa_dir'}
		./configure $cuda $float $hex $simd
		make -j$args{'njobs'}
	" );
}

if($args{'clean'} && !$args{'charm'} && !$args{'changa'}) {
	clean_charm();
	clean_changa();
}

__END__
 
=head1 NAME
 
charm++ and ChaNGa builder
 
=head1 SYNOPSIS
 
build [options]
 
 Options:
   --prefix     Base directory for the source and build directories (default: pwd)
   --charm_dir  Source directory for charm++ (default: prefix/charm)
   --changa_dir Source directory for ChaNGa (default: prefix/changa)
   --cuda       Enable CUDA (default: no)
   --charm      Build charm++ (default: yes)
   --changa     Build ChaNGa (default: yes)
   --clean      Clean before building (default: no)
   --smp        Use SMP (default: yes)
   --float      Use single-precision (default: no)
   --njobs      Number of make jobs (default: 2)
   --hex        Use hexadecapole (default: yes)
   --simd       Use SIMD [generic, sse2, avx] (default: generic)
   --help       Print this help message
=cut

