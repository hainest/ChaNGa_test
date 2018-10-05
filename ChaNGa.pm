use Configure;

package ChaNGa::Util;
BEGIN { $INC{"ChaNGa/Util.pm"} = $0; }

use base 'Exporter';
our @EXPORT_OK = qw(execute any combinations);

BEGIN {
    eval {
		require List::Util;
		List::Util->import();
		if(defined &List::Util::any) {
			*any = \&List::Util::any;
		} else {
			require List::MoreUtils;
			List::MoreUtils->import();
			if(defined &List::MoreUtils::any) {
				*any = \&List::MoreUtils::any;
			} else {
				*any = sub (&@) {
					my $code = \&{shift @_};
					for (@_) {
						return !!1 if $code->();
					}
					return !!0;
				};
			}
		}
    };
}

sub combinations {
	use Set::CrossProduct;
	use Data::Dumper;
	my $arg = (@_ == 1 && ref $_[0] eq ref []) ? $_[0] : [@_];
	return Set::CrossProduct->new($arg);
}

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
	my @names = @_;
	my $all_opts = Charm::Build::Opts::get_opts();

	# Ensure that provided option names exist
	for my $n (@names) {
		die "Unknown Charm++ build option '$n'\n" unless exists $all_opts->{$n};
	}

	my @switches = map {[$_->switches]} @{$all_opts}{@names};
	
	if (@switches > 1) {
		my $iter = ChaNGa::Util::combinations(\@switches);
		return $iter->combinations if wantarray;
		return sub { $iter->get; };
	} else {
		# Add a placeholder if no options were requested
		if(@switches == 0) {
			push @switches, [('')];
		}
		# Flatten into a simple list
		@switches = map {ref $_ eq ref [] ? @{$_} : $_} @switches;
				
		return @switches if wantarray;
		return sub { shift @switches; };
	}
}

sub get_config {
	my @opts = @_;
	my @src_dirs = (@opts, 'default');

	if (@opts > 1) {
		my $iter = ChaNGa::Util::combinations(map {[$_, '']} @opts);
		my @combos = $iter->combinations();
		@src_dirs = map {join('-', grep {$_ ne ''} @$_)} @combos;
	}
	my @switches = get_options(@opts);
	
	die unless scalar @src_dirs == scalar @switches;

	my %config = ();
	for my $i (0..@src_dirs-1) {
		$config{$src_dirs[$i] || 'default'} = $switches[$i];
	}
	return %config;
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
	    'interlist' => Configure::Option::Enable->new('interlist', ('1', '2')),
	      'rtforce' => Configure::Option::Enable->new('rtforce'),
	    'sanitizer' => Configure::Option::Enable->new('sanitizer', ('none', 'address', 'thread')),
	   'sph-kernel' => Configure::Option::Enable->new('sph-kernel', ('m4','m6','wendland')),
	     'vsigvisc' => Configure::Option::Enable->new('vsigvisc'),
   'gpu-local-walk' => Configure::Option::Enable->new('gpu-local-tree-walk')
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
	my @names;

	if ($type eq 'basic') {
		push @names, qw(hexadecapole bigkeys gpu-local-walk);
	} elsif ($type eq 'force-test') {
		push @names, qw(hexadecapole bigkeys float arch);
	} elsif($type eq 'release') {
		push @names, qw(hexadecapole changesoft float arch bigkeys sph-kernel cooling);
	} elsif ($type ne 'default') {
		# Assume comma-separated list of keys
		my $opts = ChaNGa::Build::Opts::get_opts();
		my @keys = split(',', $type);
		for my $k (@keys) {
			die "Unknown ChaNGa build option '$k'\n" unless exists $opts->{$k};
		}
		push @names, @keys;
	}

	my $all_options = ChaNGa::Build::Opts::get_opts();
	if (@names > 1) {
		my $iter = ChaNGa::Util::combinations([[''], map {[$_->switches]} @{$all_options}{@names}]);
		return $iter->combinations if wantarray;
		return sub { $iter->get; };
	}

	my @switches = (['']);
	if (@names == 1) {
		for my $s ($all_options->{$names[0]}->switches) {
			push @switches, [$s];
		}
	}
	return @switches if wantarray;
	return sub { shift @switches; };
}

1;
