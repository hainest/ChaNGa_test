package Set::CrossProduct;
use strict;
use warnings;
no warnings;
use subs qw();
use vars qw( $VERSION );
$VERSION = '2.002';

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

Matt Miller implemented the named sets feature.

=head1 COPYRIGHT AND LICENSE

Copyright © 2001-2016, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# The iterator object is a hash with these keys
#
#	arrays   - holds an array ref of array refs for each list
#   labels   - the names of the set, if applicable
#   labeled  - boolean to note if the sets are labeled or not
#	counters - the current position in each array for generating
#		combinations
#	lengths  - the precomputed lengths of the lists in arrays
#	done     - true if the last combination has been fetched
#	previous - the previous value of counters in case we want
#		to unget something and roll back the counters
#	ungot    - true if we just ungot something--to prevent
#		attempts at multiple ungets which we don't support
sub new
{
	my ( $class, $constructor_ref ) = @_;
	my $ref_type = ref $constructor_ref;
	my $self     = {};
	if ( $ref_type eq ref {} )
	{
		$self->{labeled} = 1;
		$self->{labels}  = [ sort keys %$constructor_ref ];
		$self->{arrays}  = [ @$constructor_ref{ sort keys %$constructor_ref } ];
	} elsif ( $ref_type eq ref [] )
	{
		$self->{labeled} = 1;
		$self->{arrays}  = $constructor_ref;
	} else
	{
		return;
	}
	my $array_ref = $self->{arrays};
	return unless @$array_ref > 1;
	foreach my $array (@$array_ref)
	{
		return unless ref $array eq ref [];
	}
	$self->{counters} = [ map { 0 } @$array_ref ];
	$self->{lengths}  = [ map { $#{$_} } @$array_ref ];
	$self->{previous} = [];
	$self->{ungot}    = 1;
	$self->{done} = grep( $_ == -1, @{ $self->{lengths} } ) ? 1 : 0;
	bless $self, $class;
	return $self;
}

sub _increment
{
	my $self = shift;
	$self->{previous} = [ @{ $self->{counters} } ];    # need a deep copy
	my $tail = $#{ $self->{counters} };
  COUNTERS:
	{
		if ( $self->{counters}[$tail] == $self->{lengths}[$tail] )
		{
			$self->{counters}[$tail] = 0;
			$tail--;
			if (     $tail == 0
				 and $self->{counters}[$tail] == $self->{lengths}[$tail] )
			{
				$self->done(1);
				return;
			}
			redo COUNTERS;
		}
		$self->{counters}[$tail]++;
	}
	return 1;
}

sub _decrement
{
	my $self = shift;
	my $tail = $#{ $self->{counters} };
	$self->{counters} = $self->_previous( $self->{counters} );
	$self->{previous} = $self->_previous( $self->{counters} );
	return 1;
}

sub _previous
{
	my $self     = shift;
	my $counters = $self->{counters};
	my $tail     = $#{$counters};
	return [] unless grep { $_ } @$counters;
  COUNTERS:
	{
		if ( $counters->[$tail] == 0 )
		{
			$counters->[$tail] = $self->{lengths}[$tail];
			$tail--;
			if ( $tail == 0 and $counters->[$tail] == 0 )
			{
				$counters = [ map { 0 } 0 .. $tail ];
				last COUNTERS;
			}
			redo COUNTERS;
		}
		$counters->[$tail]--;
	}
	return $counters;
}
sub labeled { !!$_[0]->{labeled} }

sub cardinality
{
	my $self    = shift;
	my $product = 1;
	foreach my $length ( @{ $self->{lengths} } )
	{
		$product *= ( $length + 1 );
	}
	return $product;
}

sub reset_cursor
{
	my $self = shift;
	$self->{counters} = [ map { 0 } @{ $self->{counters} } ];
	$self->{previous} = [];
	$self->{ungot}    = 1;
	$self->{done}     = 0;
	return 1;
}

sub get
{
	my $self = shift;
	return if $self->done;
	my $next_ref = $self->_find_ref('next');
	$self->_increment;
	$self->{ungot} = 0;
	if (wantarray) {
		return ( ref $next_ref eq ref [] ) ? @$next_ref : %$next_ref;
	} else
	{
		return $next_ref;
	}
}

sub _find_ref
{
	my ( $self, $which ) = @_;
	my $place_func =
	    ( $which eq 'next' ) ? sub { $self->{counters}[shift] }
	  : ( $which eq 'prev' ) ? sub { $self->{previous}[shift] }
	  : ( $which eq 'rand' ) ? sub { rand( 1 + $self->{lengths}[shift] ) }
	  :                        undef;
	return unless $place_func;
	my @indices = ( 0 .. $#{ $self->{arrays} } );
	if ( $self->{labels} )
	{
		return +{
			map
			{
				$self->{labels}[$_] =>
				  ${ $self->{arrays}[$_] }[ $place_func->($_) ]
			} @indices
		};
	} else
	{
		return [ map { ${ $self->{arrays}[$_] }[ $place_func->($_) ] }
				 @indices ];
	}
}

sub unget
{
	my $self = shift;
	return if $self->{ungot};
	$self->{counters} = $self->{previous};
	$self->{ungot}    = 1;

	# if we just got the last element, we had set the done flag,
	# so unset it.
	$self->{done} = 0;
	return 1;
}

sub next
{
	my $self = shift;
	return if $self->done;
	my $next_ref = $self->_find_ref('next');
	if (wantarray) {
		return ( ref $next_ref eq ref [] ) ? @$next_ref : %$next_ref;
	} else
	{
		return $next_ref;
	}
}

sub previous
{
	my $self     = shift;
	my $prev_ref = $self->_find_ref('prev');
	if (wantarray) {
		return ( ref $prev_ref eq ref [] ) ? @$prev_ref : %$prev_ref;
	} else
	{
		return $prev_ref;
	}
}
sub done { $_[0]->{done} = 1 if @_ > 1; $_[0]->{done} }

sub random
{
	my $self     = shift;
	my $rand_ref = $self->_find_ref('rand');
	if (wantarray) {
		return ( ref $rand_ref eq ref [] ) ? @$rand_ref : %$rand_ref;
	} else
	{
		return $rand_ref;
	}
}

sub combinations
{
	my $self  = shift;
	my @array = ();
	while ( my $ref = $self->get )
	{
		push @array, $ref;
	}
	if   (wantarray) { return @array }
	else             { return \@array }
}

1;
