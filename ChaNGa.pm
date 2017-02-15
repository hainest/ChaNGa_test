package ChaNGa::Options;

use overload
	'""' => sub {
		my $self = shift;
		my $str = '';
		for my $k ($self->names) {
			$str .= "\t$k => $self->{$k}\n";
		}
		return $str;
	};

sub new {
	my $self = shift;
	my ($type, $smp, $threads, $hex, $simd, $prec, $theta, $bucketsize) = @_;
	bless {
		'type' => $type, 'smp' => $smp,
		'threads' => $threads, 'hex' => $hex,
		'simd' => $simd, 'precision' => $prec,
		'theta' => $theta, 'bucketsize' => $bucketsize
	};
}
sub type : lvalue { $_[0]->{'type'}; }
sub smp : lvalue { $_[0]->{'smp'}; }
sub threads : lvalue { $_[0]->{'threads'}; }
sub hexadecapole : lvalue { $_[0]->{'hex'}; }
sub simd : lvalue { $_[0]->{'simd'}; }
sub prec : lvalue { $_[0]->{'precision'}; }
sub theta : lvalue { $_[0]->{'theta'}; }
sub bucketsize : lvalue { $_[0]->{'bucketsize'}; }
sub names { ('type', 'smp', 'threads', 'hex', 'simd', 'precision', 'theta', 'bucketsize'); }
sub listify { @{$_[0]}{$_[0]->names}; }
sub is_smp { $_[0]->{'smp'} eq 'smp'; }
sub is_gpu { $_[0]->{'type'} eq 'gpu'; }

#-----------------------------------------------------------------------------

package ChaNGa;

use base 'Exporter';
our @EXPORT_OK    = qw(get_all_options execute %launch_config);

#our @types        = ( 'cpu', 'gpu' );
#our @smp          = ( 'nosmp', 'smp' );
our @hexadecapole = ( 'hex', 'nohex' );
our @bigkeys	  = ( 'bigkeys', 'nobigkeys');
our @simd         = ( 'generic', 'sse2', 'avx' );
our @precision    = ( 'single', 'double' );
our @changesoft   = ( 'changesoft', 'nochangesoft' );
our @wendland     = ( 'wendland', 'nowendland' );
our @cooling      = ( 'none', 'planet', 'cosmo', 'grackle' );
our @theta 		  = ( '0.1', '0.2', '0.3', '0.5', '0.6', '0.7', '0.8' );
our @buckets 	  = ( 32, 64, 128, 192, 256 );

our $max_step = 0.001;	# 1 Myr
our $sim_time = 0.005;	# 5 Myrs

#basic: type, hex, changesoft, bigkeys
#force-test: $basic, smp, prec, simd
#release: $force-test, wendland, cooling

my %charm_build = (
	'types' => {
		'cpu' => '',
		'gpu' => 'cuda',
	},
	'smp' => {
		'smp'   => 'smp',
		'nosmp' => ''
	}
);
my %changa_build = (
	'types' => {
		'cpu' => '',
		'gpu' => '--with-cuda'
	},
	'hexadecapole' => {},
	'bigkeys' => {},
	'simd' => ['no']
);

our %launch_config = (
	'cpu' => {
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
	'gpu' => {
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

sub execute($;%) {
	my $cmd = shift;
	my %opts = @_;
	system($cmd);
	my $res = ( $? >> 8 ) != 0 || $? == -1 || ( $? & 127 ) != 0;
	die $cmd if ($res && $opts{'fatal'});
	print STDERR "\nFAILED:\n$cmd\n";
}

sub get_all_options {
	my @options = ();
	
	for my $type (@ChaNGa::types) {
	for my $smp (@ChaNGa::smp) {
		my $threads = $ChaNGa::launch_config{$type}{$smp}{'threads_per_pe'};
	for my $thr ( @{$threads} ) {
	for my $h (@ChaNGa::hexadecapole) {
	for my $bk (@ChaNGa::bigkeys) {
	for my $simd (@ChaNGa::simd) {
	for my $p (@ChaNGa::precision) {
		next if $p eq 'single' && $simd eq 'avx';		# not supported
		next if $type eq 'gpu' and $simd ne 'generic';  # skip the SIMD tests for now
	for my $t (@ChaNGa::theta) {
	for my $b (@ChaNGa::buckets) {
		push @options, ChaNGa::Options->new($type, $smp, $thr, $h, $simd, $p, $t, $b, $bk);
	}}}}}}}}}
	
	return @options;
}

1;
