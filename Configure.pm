package Configure::Option::pairs;
BEGIN { $INC{"Configure/Option/pairs.pm"} = $0; }

# For ancient perls without List::Util::pairs
sub new {
	my ($class, $k, $v) = @_;
	bless [$k, $v], $class;
}
sub key   { $_[0]->[0]; }
sub value { $_[0]->[1]; }

#---------------------------------------------------------------#
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
sub switches {
	my ($name, $action) = @{$_[0]}{'name','action'};
	map {"--$action-$name=$_"} @{$_[0]->{'args'}};
}
sub names {
	my $name = $_[0]->{'name'};
	map { 
		if ($_ eq 'no') { "no$name"; }
		elsif ($_ eq 'yes') { $name; }
		else { "$name-$_"; }
	} @{$_[0]->{'args'}};
}
sub items {
	my @names = $_[0]->names;
	my @vals = $_[0]->switches;
	my @pairs;
	for my $i (0..@names-1) {
		push @pairs, Configure::Option::pairs->new($names[$i], $vals[$i]);
	}
	return @pairs;
}

use overload '@{}' => sub {[&items]};

#---------------------------------------------------------------#
package Configure::Option::Enable;
use parent qw(Configure::Option);
sub new {
	my ($class, $name, @args) = @_;
	$class->SUPER::new($name, 'enable', @args ? @args : ('yes','no'));
}

#---------------------------------------------------------------#
package Configure::Option::With;
use parent qw(Configure::Option);
sub new {
	my ($class, $name, @args) = @_;
	$class->SUPER::new($name, 'with', @args ? @args : ('yes','no'));
}

#---------------------------------------------------------------#
package Configure::Option::Positional;
use parent qw(Configure::Option);
sub new {
	my ($class, $name) = @_;
	$class->SUPER::new($name);
}
sub switches { ($_[0]->{'name'}, ''); }
sub names { ("$_[0]->{'name'}", "no$_[0]->{'name'}"); }

1;

