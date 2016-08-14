package ChaNGa;

use base 'Exporter';
our @EXPORT_OK = qw(%config $base_dir @theta %size_decode @size);

our $base_dir    = "$ENV{'HOME'}/ChaNGa/";
our @theta       = ( '0.1', '0.2', '0.3', '0.4', '0.5', '0.7', '0.9' );
our %size_decode = ( '1M' => 1e6, '4M' => 4e6, '8M' => 8e6 );
our @size        = ('1M');

#my @CPU_buckets = (32, 64, 128);
#my @GPU_buckets = (32, 64, 128, 192, 256);
my @CPU_buckets = (128);
my @GPU_buckets = (128);

# Everything is done in SMP mode
our %config = (
	'CPU' => {
		'pes_per_node'   => 30,
		'cores_per_pe'   => 1,             # leave one for OS
		'threads_per_pe' => 1,             # leave one for comm thread
		'bucketsize'     => \@CPU_buckets
	},
	'CPU-SMP' => {
		'pes_per_node'   => 1,
		'cores_per_pe'   => 31,             # leave one for OS
		'threads_per_pe' => 30,             # leave one for comm thread
		'bucketsize'     => \@CPU_buckets
	},
	'CPU-SMP-SP' => {
		'pes_per_node'   => 1,
		'cores_per_pe'   => 31,
		'threads_per_pe' => 30,
		'bucketsize'     => \@CPU_buckets
	},
	'GPU-SMP' => {
		'pes_per_node'   => 1,
		'cores_per_pe'   => 15,
		'threads_per_pe' => 1,
		'bucketsize'     => \@GPU_buckets
	},
	'GPU-SMP-SP' => {
		'pes_per_node'   => 1,
		'cores_per_pe'   => 15,
		'threads_per_pe' => 1,
		 'bucketsize'     => \@GPU_buckets
	},
	'GPU-SMP-SW' => {
		'pes_per_node'   => 1,
		'cores_per_pe'   => 15,
		'threads_per_pe' => 1,
		'bucketsize'     => \@GPU_buckets
	},
	'GPU-SMP-SW-SP' => {
		'pes_per_node'   => 1,
		'cores_per_pe'   => 15,
		'threads_per_pe' => 1,
		'bucketsize'     => \@GPU_buckets
	}
);
