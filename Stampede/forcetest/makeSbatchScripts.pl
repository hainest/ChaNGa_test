use strict;
use warnings;
use Cwd qw(cwd);
use ChaNGa qw(%config);

my $baseDir = cwd();

for my $type ( keys %config ) {
	for my $numparticles ( keys %{ $config{$type} } ) {
		for my $theta ( '0.1', '0.3', '0.5', '0.7', '0.9' ) {
			my $dir = "$baseDir/$type/$numparticles/theta$theta";
			my $module = ( $type =~ /GPU/ ) ? 'module load cuda/6.0' : '';
			open my $fdOut, '>', "$dir/testdisk.sbatch" or die;
			my ( $letter, $partition ) = ( $type eq 'CPU' ) ? ( 'C', 'normal' ) : ( 'G', 'gpu' );
			my $time = ($theta < 0.5) ? '0-2:00:00' : '0-0:30:00';
			print $fdOut <<EOF
#!/bin/sh
#SBATCH --job-name=${letter}${numparticles}${theta}
#SBATCH --partition=$partition
#SBATCH --time=$time
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --error=$dir/testdisk.err
#SBATCH --output=$dir/testdisk.out
#SBATCH --mail-type=fail
#SBATCH --mail-user=thaines\@astro.wisc.edu

$module
$baseDir/$type/ChaNGa -v 1 +p 14 ++ppn 14 \"$dir/testdisk.param\"
$baseDir/$type/ChaNGa -v 1 +p 1 ++ppn 1 \"$dir/acc/testdisk.param\"
EOF
		}
	}
}
