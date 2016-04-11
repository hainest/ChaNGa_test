use strict;
use warnings;
use PDL;
use PDL::Graphics2D;
use PGPLOT;
use Getopt::Long;

#my $useGadget;
#GetOptions('g'=>\$useGadget);

my $numPart = 150000;
my @theta = (0.1,0.3,0.5,0.7,0.9);
my $theta_pdl = pdl(\@theta);
my @types = ('ChaNGa','ChaNGa_GPU','ChaNGa_GPU_multithread','Gadget3');
my @colors = ('red','blue','green','orange');

# Standard of comparison is ChaNGa with theta=0.1
my $actual = rfits('ChaNGa/acc.fits')->slice(':,:,(0)');
my $mag_actual = sqrt(sumover(xchg($actual**2,0,1)));

#if($useGadget) {
	#@types = ('../Gadget3');
	#$actual = rfits('../Gadget3/acc.fits')->slice(':,:,(0)');
	#$mag_actual = sqrt(sumover(xchg($actual**2,0,1)));
#}

my $rms = zeros(scalar @theta,scalar @types);

for my $i (0..@types-1) {
	$rms->slice(":,($i)") .= &calc_error($types[$i],rfits("$types[$i]/acc.fits"));
}

my $win = PDL::Graphics2D->new('PGPLOT',{'device'=>'force_test.png/png'});

my @envLimits = minmax($rms);
$win->env(0,1,@envLimits, {
	'border'=>{'type'=>'rel','value'=>0.03},
	'charsize'=>0.9
});

$win->tpoints($theta_pdl,$rms,{'color'=>\@colors,'SymbolSize'=>[5,3,1]});

pgsch(0.9);
pgmtxt('L',2.7,0.5,0.5,'RMS Error');
pgmtxt('B',2.7,0.5,0.5,'Opening Angle (\gh)');
$win->legend(\@types,0.2,$envLimits[0]+0.8*$envLimits[1],{
	'color'=>\@colors,
	'TextFraction'=>0.8,
	'linewidth'=>[(6)x scalar @colors],
	'charsize'=>1.2
});

$win->release();
$win->close();

sub calc_error() {
	my ($type,$data) = @_;
	
	my $mag = sqrt(sumover(xchg(($data-$actual)**2,0,1)));
	my $rms = sqrt(sumover(($mag/$mag_actual)**2)/$numPart);
	#print "$type min/max = ", join(',',map {sprintf('%6.9e',$_)} minmax($rms)), "\n";
	return $rms;
}
