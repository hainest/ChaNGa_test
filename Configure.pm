package Configure::Option;
BEGIN { $INC{"Configure/Option.pm"} = $0; }

sub new {
	my ($class, $name, $action, @args) = @_;
	bless {
		'name' => $name,
		'action'=> $action,
		'args' => \@args
	}, $class;
}
sub values {
	my ($name, $action) = @{$_[0]}{'name','action'};
	my @vals = ();
	for my $arg (@{$_[0]->{'args'}}) {
		push @vals, "--$action-$name=$arg";
	}
	return @vals;
}
sub names {
	my $name = $_[0]->{'name'};
	my @vals = ();
	for my $arg (@{$_[0]->{'args'}}) {
		push @vals, "$name-$arg";
	}
	return @vals;
}
sub iteritems {
	my @names = $_[0]->names;
	my @vals = $_[0]->values;
	my @items = ();
	for my $i (0..@names-1) {
		push @items, {'name' => $names[$i], 'value' => $vals[$i]};
	}
	return @items;
}

#-----------------------------------------------#
package Configure::Option::Enable;
use parent qw(Configure::Option);
sub new {
	my ($class, $name, @args) = @_;
	$class->SUPER::new($name, 'enable', @args ? @args : ('yes','no'));
}

#-----------------------------------------------#
package Configure::Option::With;
use parent qw(Configure::Option);
sub new {
	my ($class, $name, @args) = @_;
	$class->SUPER::new($name, 'with', @args ? @args : ('yes','no'));
}

#-----------------------------------------------#
package Configure::Option::Positional;
use parent qw(Configure::Option);
sub new {
	my ($class, $name) = @_;
	$class->SUPER::new($name, undef, ('yes','no'));
}
sub values { ($_[0]->{'name'}, ''); }

1;