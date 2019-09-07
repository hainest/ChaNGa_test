use Configure;

package ChaNGa::Util;
BEGIN { $INC{"ChaNGa/Util.pm"} = $0; }

use base 'Exporter';
our @EXPORT_OK = qw(execute any combinations mean stddev copy_dir);

BEGIN {
	my $any = sub (&@) {
		my $code = \&{shift @_};
		for (@_) {
			return !!1 if $code->();
		}
		return !!0;
	};
    eval {
		require List::Util;
		List::Util->import();
		if(defined &List::Util::any) {
			$any = \&List::Util::any;
		} else {
			require List::MoreUtils;
			List::MoreUtils->import();
			if(defined &List::MoreUtils::any) {
				$any = \&List::MoreUtils::any;
			}
		}
    };
    *any = $any;
    
    my $copy_dir = sub($$) {
		my ($from, $to) = @_;
		use File::Path qw(make_path);
		make_path $to unless -d $to;
		if(!&execute("cp -R $from $to")) {
			die "Failed to copy $from to $to: $!\n";
		}
	};
    eval{
		require File::Copy::Recursive;
		File::Copy::Recursive->import();
		if(defined &File::Copy::Recursive::dircopy) {
			$copy_dir = sub($$) {
				my ($from, $to) = @_;
				File::Copy::Recursive::dircopy($from, $to)
				or die "Failed to copy $from to $to: $!\n";
			};
		}
    };
    *copy_dir = $copy_dir;
}

sub mean {
	use List::Util qw(sum);
	return 0.0 if @{$_[0]} <= 0;
	sum(@{$_[0]}) / @{$_[0]};
}
sub stddev {
	use List::Util qw(sum);
	my ($mean, $data) = @_;
	return 0.0 if @$data <= 1; 
	sqrt(sum(map {($_-$mean)**2.0} @$data) / (@$data - 1));
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
		@src_dirs = map {join('-', sort grep {$_ ne ''} @$_)} @combos;
	}
	my @switches = get_options(@opts);
	
	die unless scalar @src_dirs == scalar @switches;

	my %config = ();
	for my $i (0..@src_dirs-1) {
		$config{$src_dirs[$i] || 'default'} = $switches[$i];
	}
	return \%config;
}

#-----------------------------------------------#
package ChaNGa::Build::Opts;
BEGIN { $INC{"ChaNGa/Build/Opts.pm"} = $0; }

{
	my %opts = (
	         'arch' => Configure::Option::Enable->new('arch', ('none','sse2','avx')),
	      'bigkeys' => Configure::Option::Enable->new('bigkeys'),
	   'changesoft' => Configure::Option::Enable->new('changesoft'),
	      'cooling' => Configure::Option::Enable->new('cooling', ('none','planet','cosmo', 'boley', 'metal', 'H2')), #,'grackle')),
	  'cullenalpha' => Configure::Option::Enable->new('cullenalpha'),
	      'damping' => Configure::Option::Enable->new('damping'),
	   'default-lb' => Configure::Option::Enable->new('default-lb', ('MultistepLB_notopo')),
	    'diffusion' => Configure::Option::Enable->new('diffusion'),
	     'dtadjust' => Configure::Option::Enable->new('dtadjust'),
	'feedbacklimit' => Configure::Option::Enable->new('feedbacklimit'),
	        'float' => Configure::Option::Enable->new('float'),
	 'hexadecapole' => Configure::Option::Enable->new('hexadecapole'),
	    'interlist' => Configure::Option::Enable->new('interlist', ('1','2')),
	 'nsmoothinner' => Configure::Option::Enable->new('nsmoothinner'),
	      'rtforce' => Configure::Option::Enable->new('rtforce'),
	    'sanitizer' => Configure::Option::Enable->new('sanitizer', ('none', 'address', 'thread')),
	    'sidminter' => Configure::Option::Enable->new('sidminter'),
	   'sph-kernel' => Configure::Option::Enable->new('sph-kernel', ('m4','m6','wendland')),
	     'splitgas' => Configure::Option::Enable->new('splitgas'),
	  'superbubble' => Configure::Option::Enable->new('superbubble'),
	     'vsigvisc' => Configure::Option::Enable->new('vsigvisc'),
   'gpu-local-walk' => Configure::Option::Enable->new('gpu-local-tree-walk'),
       'tree-build' => Configure::Option::Enable->new('tree-build', ('merge-remote','split-phase'))
	);
	
	my %categories;
	$categories{'default'} = [];
	$categories{'basic'} = [qw(hexadecapole bigkeys)];
	$categories{'force-test'} = [qw(hexadecapole tree-build float)];
	$categories{'sph-feedback'} = [qw(cooling feedbacklimit diffusion nsmoothinner superbubble)];
	$categories{'sph-viscosity'} = [qw(cullenalpha vsigvisc)];
	$categories{'sph'} = [qw(sph-kernel rtforce damping splitgas)];
	$categories{'gravity'} = [@{$categories{'force-test'}}, qw(changesoft dtadjust sidminter)];
	
	sub get_opts { return \%opts; }
	sub get_categories { return \%categories; }
}

#-----------------------------------------------#
package ChaNGa::Build;
BEGIN { $INC{"ChaNGa/Build.pm"} = $0; }

use base 'Exporter';
our @EXPORT_OK = qw(get_options);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

sub get_options {
	my ($type, $is_cuda) = @_;
	
	my $categories = ChaNGa::Build::Opts::get_categories();

	my @names;
	my $opts = ChaNGa::Build::Opts::get_opts();
	my @keys = split(',', $type);
	for my $k (@keys) {
		if (exists $categories->{$k}) {
			push @names, @{$categories->{$k}};
		} else {
			die "Unknown ChaNGa build option '$k'\n" unless exists $opts->{$k};
			push @names, $k;
		}
	}
	
	# Only add when not doing a default build
	push @names, 'gpu-local-walk' if $is_cuda && @names > 0;

	my $all_options = ChaNGa::Build::Opts::get_opts();
	if (@names > 1) {
		my $iter = ChaNGa::Util::combinations([[''], map {[$_->switches]} @{$all_options}{@names}]);
		return $iter->combinations if wantarray;
		return sub { $iter->get; };
	}

	my @switches = $type eq 'default' ? (['']) : ();
	if (@names == 1) {
		for my $s ($all_options->{$names[0]}->switches) {
			push @switches, [$s];
		}
	}

	return @switches if wantarray;
	return sub { shift @switches; };
}

sub get_config {
	my ($build_type, $charm_config, $cuda_dir) = @_;

	my @config = ();
	for my $charm_type (keys %{$charm_config}) {
		my $is_cuda = $charm_type =~ /cuda/;
		my $is_proj = $charm_type =~ /projections/;
		
		# Each configuration gets a copy of all the ChaNGa switches.
		# This consumes more memory, but is easier to handle.
		my @switches = ChaNGa::Build::get_options($build_type, $is_cuda);
		
		for my $s (@switches) {
			push @{$s}, "--with-cuda=$cuda_dir" if $is_cuda;
			push @{$s}, "--enable-projections" if $is_proj;
			push @config, {'charm_src'=>$charm_type, 'opts'=>$s};
		}
	}
	return \@config;
}

1;
