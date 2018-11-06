package MPI::Simple;

use strict;
use warnings;

my %transfer_map = ();

sub Send {
	my ($data, $dest, $tag) = @_;
	$transfer_map{$dest} = $data;
}

sub Recv {
	my $out;
	my ($source, $tag, $status) = @_;
	my $ret;
	for my $dest (keys %transfer_map) {
		$out = $transfer_map{$dest};
		delete $transfer_map{$dest};
		last;
	}
	$$status = $ret if $status;
	return $out;
}


sub Init { }
sub Comm_size { return 1; }
sub Comm_rank { return 0; }
sub Barrier { }
sub Finalize { }
sub Die { die; }
sub Die_sync { Die(); }
sub Error { return $_[0]; }
sub MPI::Simple::Mocking { return !!1; }

1;
