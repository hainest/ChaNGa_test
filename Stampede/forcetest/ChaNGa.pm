package ChaNGa;

use base 'Exporter';
our @EXPORT_OK = qw(%config);

our %config = (
	'CPU' => {
			'150k' => {
				'threads' => [16],
				'bucketsize' => [16,24,32,64,96]
			},
			'1M' => {
				'threads' => [16],
				'bucketsize' => [16,24,32,64,96]
			},
			'8M' => {
				'threads' => [16],
				'bucketsize' => [16,24,32,64,96]
			}
		},
	'GPU' => {
		'150k' => {
				'threads' => [1,2,4,8,16],
				'bucketsize' => [16,24,32,64,96,128,160,192,224,256]
		},
		'1M' => {
			'threads' => [1,2,4,8,16],
			'bucketsize' => [16,24,32,64,96,128,160,192,224,256]
		},
		'8M' => {
			'threads' => [1,2,4,8,16],
			'bucketsize' => [16,24,32,64,96,128,160,192,224,256]
		}
	}
);
