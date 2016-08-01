use strict;
use warnings;
use Getopt::Long qw(GetOptions);

sub execute($) {
	my $cmd = shift;
	system($cmd);
	use Carp qw(croak);
	croak "\n\nError executing \n\t'$cmd'\n\n" if (($? >> 8) != 0 || $? == -1 || ($? & 127) != 0);
}

my ($cuda, $charm, $changa) = ('',	1, 1);
GetOptions('with-cuda' => \$cuda, 'with-charm' => \$charm, 'with-changa' => \$changa);
$cuda = 'cuda' if $cuda;

print "cuda = $cuda, charm = $charm, changa = $changa\n"; exit;

if ($charm) {
	execute("
		# Fix for RCA module issues (https://charm.cs.illinois.edu/redmine/issues/534)
		export PE_PKGCONFIG_LIBS=cray-rca:$ENV{PE_PKGCONFIG_LIBS}
		
		cd charm
		export CUDA_DIR=$ENV{CRAY_CUDATOOLKIT_DIR}
		rm -rf bin include lib lib_so tmp VERSION gni-crayxe*
		./build ChaNGa gni-crayxe hugepages $cuda smp --enable-lbuserdata -j2 -optimize
	");
}

if ($changa) {
	my $cuda_conf = ($cuda) ? "--with-cuda=$ENV{CRAY_CUDATOOLKIT_DIR}" : '';

	execute("
		cd changa;
		./configure $cuda_conf;
		make clean;
		rm -f *.a;
		make -j2;
	");
}
