use strict;
use warnings;
use ChaNGa qw(%config @theta %size_decode);
use PDL;
use PDL::NiceSlice;
use PDL::Graphics2D;
use PGPLOT;

my $base_dir = 'results';
my $num_particles = '1M';
my @types = sort keys %config;
#colors = ('red', 'blue', 'orange', 'darkviolet', 'green', 'coral')
my @colors = ('red','blue','orange','purple', 'green', 'coral');

my @symbol_sizes = (6,5,4,3,2,1);
my $theta_pdl = pdl(\@theta);

# Comparison is CPU with theta=0.1
my $comparison = rfits("$base_dir/CPU/$num_particles.acc.fits")->slice(':,:,(0)');
my $comparison_mag = PDL::sqrt(sumover(xchg($comparison,0,1)**2.0));

my $rms = zeros(scalar @theta, scalar @types);

for my $i (0..@types-1) {
	print "Opening $base_dir/$types[$i]/$num_particles.acc.fits\n";
	my $data = rfits("$base_dir/$types[$i]/$num_particles.acc.fits");
	my $mag = PDL::sqrt(sumover(xchg($data-$comparison,0,1)**2.0));
	$rms(:,($i)) .= PDL::sqrt(sumover(($mag/$comparison_mag)**2.0)/$size_decode{$num_particles});
}

my $win = PDL::Graphics2D->new('PGPLOT',{'device'=>'force_test.ps/cps', 'WindowWidth'=>5, 'AspectRatio'=>8.5/11.0});

my @x_limits = minmax($theta_pdl);
my $mask = ones(dims($rms));
$mask(0,0) .= 0;
my $y = zeros(dims($rms));
whereND($y,$mask) .= PDL::log10(whereND($rms,$mask))+4;
my @y_limits = minmax(whereND($y,$mask));

$win->env(@x_limits,@y_limits, {
	'border'=>{'type'=>'rel','value'=>0.06},
	'charsize'=>0.9,
	'axis' => 'LOGY'
});

for my $i (0..@types-1) {
	my $type = $types[$i];
	my $c = $colors[$i];
	my $ss = $symbol_sizes[$i];
	for my $j (0..@theta-1) {
		my $t = $theta[$j];
		next if $type eq 'CPU' && $j == 0;
		$win->hold();
		$win->points($t,$y($j,$i),{'color'=>$c,'SymbolSize'=>$ss});
		$win->release();
	}
}

pgsch(0.9);
pgmtxt('L',2.7,0.5,0.5,'log(RMS Error) + 4');
pgmtxt('B',2.7,0.5,0.5,'Opening Angle (\gh)');
$win->legend([map {s/WangKernelTest/Wang/gi; $_;} @types],0.2,PDL::log10(10**$y_limits[0]+0.8*10**$y_limits[1]),{
	'color'=>\@colors,
	'TextFraction'=>0.8,
	'linewidth'=>[(6)x scalar @colors],
	'charsize'=>1.2
});
