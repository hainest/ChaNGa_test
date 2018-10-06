use strict;
use warnings;
use lib 'MPI';
use MPI::Simple;

MPI::Simple::Init();
my $rank = MPI::Simple::Comm_rank();
if ( $rank == 1 ) {
	my @data = (1, 2, 3);
	MPI::Simple::Send(\@data, 0, 123);
}
else {
	my $status = 0;
	my $msg = MPI::Simple::Recv(1, 123, $status);
	print "$rank received: '@{$msg}'\nstatus = $status\n";
}
MPI::Simple::Finalize();
