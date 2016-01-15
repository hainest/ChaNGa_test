package ChaNGa;

use base 'Exporter';
our @EXPORT_OK = qw(%config $base_dir @theta);

our $base_dir = "$ENV{'HOME'}/ChaNGa/";
our @theta = ('0.1', '0.3', '0.5', '0.7', '0.9');

my @CPU_buckets = (32, 64, 128);
my @GPU_buckets = (32, 64, 128, 192, 256);

our %config = (
	'CPU' => {
		'1M' => {
			'threads_per_pe' => [1],
			'pes_per_node'   => [32],
			'bucketsize'     => \@CPU_buckets
		},
		'4M' => {
			'threads_per_pe' => [1],
			'pes_per_node'   => [32],
			'bucketsize'     => \@CPU_buckets
		}
	},
	'GPU' => {
		'1M' => {
			'threads_per_pe' => [1],
			'pes_per_node'   => [1, 32],
			'bucketsize'     => \@GPU_buckets
		},
		'4M' => {
			'threads_per_pe' => [1],
			'pes_per_node'   => [1, 32],
			'bucketsize'     => \@GPU_buckets
		}
	},
	'GPU-SMP' => {
		'1M' => {
			'threads_per_pe' => [1, 2, 8, 31, 62],
			'pes_per_node'   => [1],
			'bucketsize'     => \@GPU_buckets
		},
		'4M' => {
			'threads_per_pe' => [1, 2, 8, 31, 62],
			'pes_per_node'   => [1],
			'bucketsize'     => \@GPU_buckets
		}
	}
);
