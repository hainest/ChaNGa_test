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
	_Send( $stor, $_[1], $_[2] );
}

sub Recv {
	my $out;
	my ( $source, $tag, $status ) = @_;
	$out = _Recv( $source, $tag, $status );
	return ${ thaw($out) };
}


sub Init { _Init(); }
sub Comm_size { _Comm_size(); }
sub Comm_rank { _Comm_rank(); }
sub Barrier { _Barrier(); }
sub Finalize { _Finalize(); }

1;
