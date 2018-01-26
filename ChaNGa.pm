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
package ChaNGa::Build;
BEGIN { $INC{"ChaNGa/Build.pm"} = $0; }

use base 'Exporter';
our @EXPORT_OK = qw(%launch_config get_cuda_options
					get_basic_options get_forcetest_options
					get_release_options);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

our $cuda 		  = Configure::Option::With->new('cuda');
our $hexadecapole = Configure::Option::Enable->new('hexadecapole');
our $simd		  = Configure::Option::Enable->new('simd', ('generic', 'sse2', 'avx'));
our $float		  = Configure::Option::Enable->new('float');
our $bigkeys	  = Configure::Option::Enable->new('bigkeys');
our $changesoft	  = Configure::Option::Enable->new('changesoft');
our $wendland	  = Configure::Option::Enable->new('wendland');
our $cooling	  = Configure::Option::Enable->new('cooling', ('no','planet','cosmo','grackle'));

sub get_cuda_options {
	my @opts = ();
	my @charm = $Charm::Build::cuda->items;
	my @changa = $ChaNGa::Build::cuda->items;
	for my $i (0..@charm-1) {
		push @opts, {'charm' => $charm[$i], 'changa' => $changa[$i]};
	}
	return @opts;
}
sub get_basic_options {
	my @opts = ();
	for my $hex (@$ChaNGa::Build::hexadecapole) {
	for my $cs (@$ChaNGa::Build::changesoft) {
	for my $bg (@$ChaNGa::Build::bigkeys) {
		push @opts, [$hex, $cs, $bg];
	}}}
	return \@opts;
}
sub get_forcetest_options {
	my @opts = ();
	for my $hex (@$ChaNGa::Build::hexadecapole) {
	for my $cs (@$ChaNGa::Build::changesoft) {
	for my $float (@$ChaNGa::Build::float) {
	for my $simd (@$ChaNGa::Build::simd) {
		push @opts, [$hex, $cs, $float, $simd];
	}}}}
	return \@opts;
}
sub get_release_options {
	my @opts = ();
	for my $cool (@$ChaNGa::Build::cooling) {
	for my $bk (@$ChaNGa::Build::bigkeys) {
		push @opts, [$cool, $bk];
	}}
	return \@opts;
}
sub get_release_full_options {
	my @opts = ();
	
	for my $hex (@$ChaNGa::Build::hexadecapole) {
	for my $cs (@$ChaNGa::Build::changesoft) {
	for my $float (@$ChaNGa::Build::float) {
	for my $simd (@$ChaNGa::Build::simd) {
	for my $bk (@$ChaNGa::Build::bigkeys) {
	for my $wend (@$ChaNGa::Build::wendland) {
	for my $cool (@$ChaNGa::Build::cooling) {
		push @opts, [$hex, $cs, $float, $simd, $bk, $wend, $cool];
	}}}}}}}
	return \@opts;
}

our %launch_config = (
	'cuda' => {
		'smp' => {
			'pes_per_node'   => 1,
			'cores_per_pe'   => 30,
			'threads_per_pe' => [30]
		},
		'nosmp' => {
			'pes_per_node'   => 30,
			'cores_per_pe'   => 1,
			'threads_per_pe' => [1]
		}
	},
	'nocuda' => {
		'smp' => {
			'pes_per_node'   => 1,
			'cores_per_pe'   => 15,
			'threads_per_pe' => [ 1, 2, 4, 8, 15 ]
		},
		'nosmp' => {
			'pes_per_node'   => 15,
			'cores_per_pe'   => 1,
			'threads_per_pe' => [1]
		}
	}
);

1;

