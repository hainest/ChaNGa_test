use strict;
use warnings;
use ChaNGa qw(%config @theta);
use PDL;
use PDL::NiceSlice;

my $simTime = 0.005;                      # 5 Myrs
my $snapshot_suffix = sprintf('%06s',int($simTime*1e3));
my $base_dir = 'results/';

my %size_decode = ('1M' => 1e6, '4M' => 4e6, '8M' => 8e6);

for my $type (keys %config) {
	for my $numparticles (keys %{$config{$type}}) {
		my $acc = zeros($size_decode{$numparticles},3,scalar @theta);
		for my $pes_per_node (@{$config{$type}{$numparticles}{'pes_per_node'}}) {
			for my $threads (@{$config{$type}{$numparticles}{'threads_per_pe'}}) {
				for my $t (@theta) {
					for my $b (@{$config{$type}{$numparticles}{'bucketsize'}}) {
						my $dir    = "$base_dir/$type/$numparticles/$pes_per_node/$threads/$t/$b/acc";
						my $prefix = "$type+$numparticles+$pes_per_node+$threads+$t+$b";

						open my $fdIn, '<', "$dir/$prefix.acc.out.000000.acc2" or die "Unable to open $dir/$prefix.acc.out.000000.acc2: $!\n";
						
						# Be sure to skip the header line that contains the number of particles
						$acc(:,:,(3)) .= rcols($fdIn,[],{'LINES'=>'1:-1'})->reshape($size_decode{$numparticles},3);
					}
				}
			}
		}
		PDL::wfits($acc,"$base_dir/$type/$numparticles.acc.fits");
	}
}

my %timings = ();

for my $type (keys %config) {
	for my $t (@theta) {
		open my $fdIn, '<', "$type/acc/";
		while(<$fdIn>) {
			chomp;
			next if $_ eq '' || /^#/;
			/Running (.+?) for theta=\d\.\d\.\.\.done\. \((.+?) seconds\)/;
			my ($type,$time) = ($1,$2);
			push @{$timings{$type}}, $time;
		}
	}
}

for my $type (keys %timings) {
	$timings{$type} = pdl($timings{$type});
}

my $win = PDL::Graphics2D->new('PGPLOT',{'device'=>'timings.ps/cps'});

$win->env(0,1,0,50,{
	'plotposition'=>[0.1,0.9,0.5,0.9],
	'border'=>{'type'=>'rel','value'=>0.02},
	'charsize'=>0.9,
	'axis'=>['CTS','BCTSN']
});

$win->hold();
$win->points($theta,$timings{'ChaNGa'}/100,{'color'=>'orange'});
$win->points($theta,$timings{'ChaNGa_GPU'}/100,{'color'=>'red'});
$win->points($theta,$timings{'ChaNGa_GPU_multithread'}/100,{'color'=>'green'});
$win->points($theta,$timings{'Gadget3'}/100,{'color'=>'blue'});

$win->legend(['ChaNGa','ChaNGa_GPU','ChaNGa_GPU_multithread','Gadget3'],0.5,30,{
	'color'=>['orange','red','green','blue'],
	'textfraction'=>0.8,
	'charsize'=>1.0
});

pgqch($a);
pgsch(0.9);
pgmtxt('L',2.5,0.5,0.5,'Time per step (s)');
pgsch($a);
$win->release();

$win->env(0,1,0,9,{
	'plotposition'=>[0.1,0.9,0.1,0.5],
	'border'=>{'type'=>'rel','value'=>0.02},
	'charsize'=>0.9
});

$win->hold();
$win->points($theta,$timings{'ChaNGa'}/$timings{'Gadget3'},{'color'=>'blue'});
$win->points($theta,$timings{'ChaNGa'}/$timings{'ChaNGa_GPU'},{'color'=>'red'});
$win->points($theta,$timings{'ChaNGa'}/$timings{'ChaNGa_GPU_multithread'},{'color'=>'green'});
$win->arrow(-2,2,2,2,{'color'=>'lightgrey'});
$win->arrow(-2,3,2,3,{'color'=>'lightgrey'});

$win->legend(['ChaNGa_GPU','ChaNGa_GPU_multithread','Gadget3'],0.5,7,{
	'color'=>['red','green','blue'],
	'textfraction'=>0.8,
	'charsize'=>1.0
});

pgsch(0.9);
pgmtxt('L',2.5,0.5,0.5,'Speedup (relative to ChaNGa)');
pgmtxt('B',2.5,0.5,0.5,'Opening Angle (\gh)');
$win->release();
$win->close();
