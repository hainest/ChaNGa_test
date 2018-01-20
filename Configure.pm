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

