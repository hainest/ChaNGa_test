use v5.10;
use strict;
use warnings;
use ChaNGa;
use Cwd qw(cwd);
use PDL;

#Inline->bind('Pdlpp' => q{
#    pp_def('diff_sigma_window',
#        'Pars' => 'a(n); [o] b(n);',
#        'OtherPars' => 'int winSize; double nsigma; ',
#        'GenericTypes' => ['D'],
#        'Code' => q{
#			int i, j, finalLen;
#            double sum, avg, sigma, tmp;
#            int nwin = $SIZE(n) / $COMP(winSize);
#            for(i=0; i<nwin*$COMP(winSize); i+=$COMP(winSize)) {
#                sigma = sqrt(sum / $COMP(winSize));
#                for(j=0; j<$COMP(winSize); j++) {
#                	tmp = 0.0D;
#                	if(fabs( $a(n=>j+i) - avg) > $COMP(nsigma)*sigma) {
#                		if($a(n=>j+i) > 0)
#                        	tmp = $a(n=>j+i) - avg;
#                    	else
#                    		tmp = $a(n=>j+i) + avg;
#                	}
#                    $b(n=>i+j) = tmp;
#                }
#            }
#        }
#    );
#});
#
#if (@ARGV != 2) {
#	print "Usage: $0 base_dir output_file\n";
#	exit;
#}
#
#my ($base_dir, $output_file) = @ARGV;
#
#my $rms_error = pdl();
#
#for my $type (0..@ChaNGa::types-1) {
#for my $smp (0..@ChaNGa::smp-1) {
#	my $threads = $ChaNGa::launch_config{$type}{$smp}{'threads_per_pe'};
#for my $thr (0..@{$threads}-1) {
#for my $h (0..@ChaNGa::hexadecapole-1) {
#for my $simd (0..@ChaNGa::simd-1) {
#for my $p (0..@ChaNGa::precision-1) {
#	next if $p eq 'single' && $simd eq 'avx';		# not supported
#	next if $type eq 'GPU' and $simd ne 'generic';  # skip the SIMD tests for now
#for my $t (0..@ChaNGa::theta-1) {
#for my $b (0..@ChaNGa::buckets-1) {
#	my $input_file = "$base_dir/$type/$smp/$thr/$h/$simd/$p/$t/$b/.acc2";
#	print "Processing $input_file\n";
#	$rms_error($type, $smp, $thr, $h, $simd, $p, $t, $b) .= readfraw($input_file);
#}}}}}}}}
#
#PDL::wfits($rms_error, $output_file);

