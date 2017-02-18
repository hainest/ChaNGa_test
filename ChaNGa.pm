use Configure;

package ChaNGa::Sim;

our $max_step = 0.001;	# 1 Myr
our $sim_time = 0.005;	# 5 Myrs

our @theta	 = ( '0.1', '0.2', '0.3', '0.5', '0.6', '0.7', '0.8' );
our @buckets = ( 32, 64, 128, 192, 256 );

#-----------------------------------------------#
package ChaNGa::Util;
BEGIN { $INC{"ChaNGa/Util.pm"} = $0; }

use base 'Exporter';
our @EXPORT_OK = qw(execute);

sub execute($;%) {
	my $cmd = shift;
	print "$cmd\n";
#	my %opts = @_;
#	system($cmd);
#	my $failed = ( $? >> 8 ) != 0 || $? == -1 || ( $? & 127 ) != 0;
#	die $cmd if ($failed && $opts{'fatal'});
#	return !$failed;
}

#-----------------------------------------------#
package Charm::Build;

our $architecture = Configure::Option::Positional->new('cuda');
our $smp          = Configure::Option::Positional->new('smp');

#-----------------------------------------------#
package ChaNGa::Build;
BEGIN { $INC{"ChaNGa/Build.pm"} = $0; }

use base 'Exporter';
our @EXPORT_OK = qw(%launch_config %charm_decode);

our $hexadecapole = Configure::Option::Enable->new('hexadecapole');
our $sse          = Configure::Option::Enable->new('sse');
our $avx		  = Configure::Option::Enable->new('avx');
our $float		  = Configure::Option::Enable->new('float');
our $bigkeys	  = Configure::Option::Enable->new('bigkeys');
our $changesoft	  = Configure::Option::Enable->new('changesoft');
our $wendland	  = Configure::Option::Enable->new('wendland');
our $cooling	  = Configure::Option::Enable->new('cooling', ('no','planet','cosmo','grackle'));

our %charm_decode = (
	'cuda-no' => '--with-cuda=no',
	'cuda-yes' => '--with-cuda',
);

our %launch_config = (
	'cuda-no' => {
		'smp-yes' => {
			'pes_per_node'   => 1,
			'cores_per_pe'   => 30,
			'threads_per_pe' => [30]
		},
		'smp-no' => {
			'pes_per_node'   => 30,
			'cores_per_pe'   => 1,
			'threads_per_pe' => [1]
		}
	},
	'cuda-yes' => {
		'smp-yes' => {
			'pes_per_node'   => 1,
			'cores_per_pe'   => 15,
			'threads_per_pe' => [ 1, 2, 4, 8, 15 ]
		},
		'smp-no' => {
			'pes_per_node'   => 15,
			'cores_per_pe'   => 1,
			'threads_per_pe' => [1]
		}
	}
);

#sub new {
#	my $self = shift;
#	my ($type, $smp, $threads, $hex, $simd, $prec, $theta, $bucketsize) = @_;
#	bless {
#		'type' => $type, 'smp' => $smp,
#		'threads' => $threads, 'hex' => $hex,
#		'simd' => $simd, 'precision' => $prec,
#		'theta' => $theta, 'bucketsize' => $bucketsize
#	};
#}
#sub type : lvalue { $_[0]->{'type'}; }
#sub smp : lvalue { $_[0]->{'smp'}; }
#sub threads : lvalue { $_[0]->{'threads'}; }
#sub hexadecapole : lvalue { $_[0]->{'hex'}; }
#sub simd : lvalue { $_[0]->{'simd'}; }
#sub prec : lvalue { $_[0]->{'precision'}; }
#sub theta : lvalue { $_[0]->{'theta'}; }
#sub bucketsize : lvalue { $_[0]->{'bucketsize'}; }
#sub names { ('type', 'smp', 'threads', 'hex', 'simd', 'precision', 'theta', 'bucketsize'); }
#sub listify { @{$_[0]}{$_[0]->names}; }
#sub is_smp { $_[0]->{'smp'} eq 'smp'; }
#sub is_gpu { $_[0]->{'type'} eq 'gpu'; }
#sub get_all_options {
#	my @options = ();
#	
#	for my $type (@ChaNGa::architecture) {
#	for my $smp (@ChaNGa::smp) {
#		my $threads = $ChaNGa::launch_config{$type}{$smp}{'threads_per_pe'};
#	for my $thr ( @{$threads} ) {
#	for my $h (@ChaNGa::hexadecapole) {
#	for my $simd (@ChaNGa::simd) {
#	for my $p (@ChaNGa::precision) {
#		next if $p eq 'single' && $simd eq 'avx';		# not supported
#		next if $type eq 'gpu' and $simd ne 'generic';  # skip the SIMD tests for now
#	for my $t (@ChaNGa::theta) {
#	for my $b (@ChaNGa::buckets) {
#		push @options, ChaNGa::Option->new($type, $smp, $thr, $h, $simd, $p, $t, $b);
#	}}}}}}}}
#	
#	return @options;
#}

1;
