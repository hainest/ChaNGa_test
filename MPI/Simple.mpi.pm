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
	my ($data, $dest, $tag) = @_;
	my $stor = nfreeze(\$data);
	mpi_simple_send($stor, $dest, $tag);
}

sub Recv {
	my $out;
	my ($source, $tag, $status) = @_;
	my $ret;
	if ($source eq 'any') {
		$out = mpi_simple_recv_any($tag, $ret);
	} else {
		$out = mpi_simple_recv($source, $tag, $ret);
	}
	$$status = $ret if $status;
	return ${ thaw($out) };
}


sub Init { mpi_simple_init(); }
sub Comm_size { mpi_simple_comm_size(); }
sub Comm_rank { mpi_simple_comm_rank(); }
sub Barrier { mpi_simple_barrier(); }
sub Finalize { mpi_simple_finalize(); }
sub Die { Finalize(); die $_[0]; }
sub Die_sync { Barrier(); Die(@_); }
sub Exit { Finalize(); exit(0); }
sub Exit_sync { Barrier(); Exit(); };
sub Error { mpi_simple_error($_[0]); }
sub MPI::Simple::Mocking { return !!0; }

1;
