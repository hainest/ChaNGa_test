package ChaNGa;

use base 'Exporter';
our @EXPORT_OK = qw(%config $base_dir);

our $base_dir = "$ENV{'HOME'}/ChaNGa/";

my $max_threads = 14;    # Leave 1 for the OS and 1 for the Comm thread

my @CPU_buckets = (32, 64, 128);
my @GPU_buckets = (32, 64, 128, 192, 256);

our %config = (
	'CPU' => {
		'150k' => {
			'threads_per_node' => [$max_threads],
			'bucketsize'       => \@CPU_buckets
		},
		'1M' => {
			'threads_per_node' => [$max_threads],
			'bucketsize'       => \@CPU_buckets
		},
#		'8M' => {
#			'threads_per_node' => [$max_threads],
#			'bucketsize'       => \@CPU_buckets
#		}
	},
	'GPU' => {
		'150k' => {
			'threads_per_node' => [1, $max_threads],
			'bucketsize'       => \@GPU_buckets
		},
		'1M' => {
			'threads_per_node' => [1, $max_threads],
			'bucketsize'       => \@GPU_buckets
		},
#		'8M' => {
#			'threads_per_node' => [1, $max_threads],
#			'bucketsize'       => \@GPU_buckets
#		}
	},
	'GPU-SMP' => {
		'150k' => {
			'threads_per_node' => [1, 2, 4, 8, $max_threads],
			'bucketsize'       => \@GPU_buckets
		},
		'1M' => {
			'threads_per_node' => [1, 2, 4, 8, $max_threads],
			'bucketsize'       => \@GPU_buckets
		},
#		'8M' => {
#			'threads_per_node' => [1, 2, 4, 8, $max_threads],
#			'bucketsize'       => \@GPU_buckets
#		}
	}
);
