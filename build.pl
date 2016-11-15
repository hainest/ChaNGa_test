use strict;
use warnings;
use Getopt::Long qw(GetOptions);

sub execute($) {
	my $cmd = shift;
	system($cmd);
	use Carp qw(croak);
	croak "\n\nError executing \n\t'$cmd'\n\n" if ( ( $? >> 8 ) != 0 || $? == -1 || ( $? & 127 ) != 0 );
}

my ( $cuda, $charm, $changa, $clean, $smp, $float ) = ( '', 1, 1, 0 , 1, 0);
GetOptions(
	'with-cuda' => \$cuda,
	'charm!'    => \$charm,
	'changa!'   => \$changa,
	'clean'     => \$clean,
	'smp!'		=> \$smp,
	'float'		=> \$float
) or exit;
$cuda = 'cuda' if $cuda;
$smp  = ($smp) ? 'smp' : '';
$float = ($float) ? '--enable-float' : '';

if ($clean) {
	execute( "
		cd charm
		rm -rf bin include lib lib_so tmp VERSION gni-crayxe*
	" );
	execute( "
		cd changa
		rm -f *.a *.o config.status Makefile.dep Makefile cuda.mk ChaNGa charmrun
	" );
}
if ($charm) {
	execute( "
		# Fix for RCA module issues (https://charm.cs.illinois.edu/redmine/issues/534)
		export PE_PKGCONFIG_LIBS=cray-rca:$ENV{PE_PKGCONFIG_LIBS}
		
		cd charm
		export CUDA_DIR=$ENV{CRAY_CUDATOOLKIT_DIR}
		./build ChaNGa gni-crayxe hugepages $cuda $smp --enable-lbuserdata -j2 -optimize
	" );
}

if ($changa) {
	my $cuda_conf = ($cuda) ? "--with-cuda=$ENV{CRAY_CUDATOOLKIT_DIR}" : '';
	execute( "
		cd changa
		./configure $cuda_conf $float
		make -j2
	" );
}
