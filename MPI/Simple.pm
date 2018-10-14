package MPI::Simple;

use strict;
use warnings;
use Storable qw(nfreeze thaw);

require DynaLoader;
use vars qw(@ISA $VERSION);
@ISA = qw(DynaLoader);
$VERSION = '0.03';

bootstrap MPI::Simple;

sub Send {
	my $stor = nfreeze( \$_[0] );
	mpi_simple_send( $stor, $_[1], $_[2] );
}

sub Recv {
	my $out;
	my ( $source, $tag, $status ) = @_;
	if ($source eq 'any') {
		$out = mpi_simple_recv_any($tag, $status);
	} else {
		$out = mpi_simple_recv($source, $tag, $status);
	}
	
	return ${ thaw($out) };
}


sub Init { mpi_simple_init(); }
sub Comm_size { mpi_simple_comm_size(); }
sub Comm_rank { mpi_simple_comm_rank(); }
sub Barrier { mpi_simple_barrier(); }
sub Finalize { mpi_simple_finalize(); }
sub Die { Finalize(); die; }
sub Die_sync { Barrier(); Die(); }

1;
