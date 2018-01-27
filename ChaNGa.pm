use Configure;

package ChaNGa::Util;
BEGIN { $INC{"ChaNGa/Util.pm"} = $0; }

use base 'Exporter';
our @EXPORT_OK = qw(execute);

sub execute($) {
	my $cmd = shift;
	system($cmd);
	return !(( $? >> 8 ) != 0 || $? == -1 || ( $? & 127 ) != 0);
}

#-----------------------------------------------#
package Charm::Build::Opts;
BEGIN { $INC{"Charm/Build/Opts.pm"} = $0; }
{
	my %opts = (
		   'cuda' => Configure::Option::Positional->new('cuda'),
		    'smp' => Configure::Option::Positional->new('smp'),
	'projections' => Configure::Option::Enable->new('tracing')
	);
	sub get_opts() { return \%opts; }
}

#-----------------------------------------------#
package Charm::Build;
BEGIN { $INC{"Charm/Build.pm"} = $0; }

use base 'Exporter';
our @EXPORT_OK = qw(get_options);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

sub get_options {
	my (%args) = @_;
	my $all_opts = Charm::Build::Opts::get_opts();

	my @opts;	
	for my $k (keys %args) {
		die "Unknown Charm++ build option '$k'\n" unless exists $all_opts->{$k}; 
		push @opts, $k if $args{$k};
	}

	if (@opts > 1) {
		use Set::CrossProduct;
		my $iter = Set::CrossProduct->new([map {[$_->switches]} @{$all_opts}{@opts}]);
		return $iter->combinations if wantarray;
		return sub { $iter->get; };
	}
	
	my @switches;
	if (@opts == 1) {
		@switches = map {[$_]} $all_opts->{$opts[0]}->switches;
	} else {
		push @switches, [('')];
	}
	return @switches if wantarray;
	return sub { shift @switches; };
}

#-----------------------------------------------#
package ChaNGa::Build::Opts;
BEGIN { $INC{"ChaNGa/Build/Opts.pm"} = $0; }

{
	my %opts = (
	         'arch' => Configure::Option::Enable->new('arch', ('none','sse2','avx')),
	      'bigkeys' => Configure::Option::Enable->new('bigkeys'),
	   'changesoft' => Configure::Option::Enable->new('changesoft'),
	      'cooling' => Configure::Option::Enable->new('cooling', ('none','planet','cosmo','grackle')),
	  'cullenalpha' => Configure::Option::Enable->new('cullenalpha'),
	      'damping' => Configure::Option::Enable->new('damping'),
	   'default-lb' => Configure::Option::Enable->new('default-lb', ('MultistepLB_notopo')),
	    'diffusion' => Configure::Option::Enable->new('diffusion'),
	     'dtadjust' => Configure::Option::Enable->new('dtadjust'),
	'feedbacklimit' => Configure::Option::Enable->new('feedbacklimit'),
	        'float' => Configure::Option::Enable->new('float'),
	 'hexadecapole' => Configure::Option::Enable->new('hexadecapole'),
	      'rtforce' => Configure::Option::Enable->new('rtforce'),
	    'sanitizer' => Configure::Option::Enable->new('sanitizer', ('none', 'address', 'thread')),
	   'sph-kernel' => Configure::Option::Enable->new('sph-kernel', ('m4','m6','wendland')),
	     'vsigvisc' => Configure::Option::Enable->new('vsigvisc')
	);
	sub get_opts { return \%opts; }
}

#-----------------------------------------------#
package ChaNGa::Build;
BEGIN { $INC{"ChaNGa/Build.pm"} = $0; }

use base 'Exporter';
our @EXPORT_OK = qw(get_options);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

sub get_options {
	my ($type, %args) = @_;
	my @opts;
	
	if ($type eq 'basic') {
		push @opts, qw(hexadecapole bigkeys);
	} elsif ($type eq 'force-test') {
		push @opts, qw(hexadecapole bigkeys float arch);
	} elsif($type eq 'release') {
		push @opts, qw(hexadecapole changesoft float arch bigkeys sph-kernel cooling);
	} else {
		# Assume comma-separated list of keys
		my $opts = ChaNGa::Build::Opts::get_opts();
		my @keys = split(',', $type);
		for my $k (@keys) {
			die "Unknown ChaNGa build option '$k'\n" unless exists $opts->{$k};
		}
		push @opts, @keys;
	}
	use Set::CrossProduct;
	my $iter = Set::CrossProduct->new([map {[$_->switches]} @{ChaNGa::Build::Opts::get_opts()}{@opts}]);
	return $iter->combinations if wantarray;
	return sub { $iter->get; };
}

1;
