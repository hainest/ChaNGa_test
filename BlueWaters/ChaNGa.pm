package ChaNGa;

use base 'Exporter';
our @EXPORT_OK = qw(%config $base_dir @theta);

our $base_dir = "$ENV{'HOME'}/ChaNGa/";
our @theta = ('0.1', '0.3', '0.5', '0.7', '0.9');

#my @CPU_buckets = (32, 64, 128);
#my @GPU_buckets = (32, 64, 128, 192, 256);
my @CPU_buckets = (128);
my @GPU_buckets = (128);

our %config = (
#	'CPU' => {
#		'1M' => {
#			'threads_per_pe' => [1],
#			'pes_per_node'   => [31],
#			'bucketsize'     => \@CPU_buckets
#		},
#		'4M' => {
#			'threads_per_pe' => [1],
#			'pes_per_node'   => [31],
#			'bucketsize'     => \@CPU_buckets
#		}
#	},
	'CPU-SMP' => {
		'1M' => {
			'threads_per_pe' => [31],
			'pes_per_node'   => [1],
			'bucketsize'     => \@CPU_buckets
		},
#		'4M' => {
#			'threads_per_pe' => [31],
#			'pes_per_node'   => [1],
#			'bucketsize'     => \@CPU_buckets
#		}
	},
#	# The non-SMP GPU version is severely broken. Because there is a GPU manager per PE,
#	# it doesn't know that other processes are trying to use the GPU and it overcommits
#	# the device memory. The fix is to use only 1 or 2 PEs per node.
#	'GPU1' => {
#		'1M' => {
#			'threads_per_pe' => [1],
#			'pes_per_node'   => [1],
#			'bucketsize'     => \@GPU_buckets
#		},
#		'4M' => {
#			'threads_per_pe' => [1],
#			'pes_per_node'   => [1],
#			'bucketsize'     => \@GPU_buckets
#		}
#	},
#	'GPU2' => {
#		'1M' => {
#			'threads_per_pe' => [1],
#			'pes_per_node'   => [2],
#			'bucketsize'     => \@GPU_buckets
#		},
#		'4M' => {
#			'threads_per_pe' => [1],
#			'pes_per_node'   => [2],
#			'bucketsize'     => \@GPU_buckets
#		}
#	},
	'GPU-SMP' => {
		'1M' => {
#			'threads_per_pe' => [1, 8, 15],
			'threads_per_pe' => [1],
			'pes_per_node'   => [1],
			'bucketsize'     => \@GPU_buckets
		},
#		'4M' => {
#			'threads_per_pe' => [1, 8, 15],
#			'pes_per_node'   => [1],
#			'bucketsize'     => \@GPU_buckets
#		}
	},
	'GPU-SMP-WangKernelTest' => {
		'1M' => {
#			'threads_per_pe' => [1, 8, 15],
			'threads_per_pe' => [1],
			'pes_per_node'   => [1],
			'bucketsize'     => \@GPU_buckets
		},
#		'4M' => {
#			'threads_per_pe' => [1, 8, 15],
#			'pes_per_node'   => [1],
#			'bucketsize'     => \@GPU_buckets
#		}
	}
);
