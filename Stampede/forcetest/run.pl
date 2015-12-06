use v5.10.1;
use strict;
use warnings;
use Carp qw(croak);
use ChaNGa qw(%config);
use Cwd qw(cwd);

my $baseDir = cwd();

for my $type ( keys %config ) {
	for my $numparticles ( keys %{ $config{$type} } ) {
		for my $theta ( '0.1', '0.3', '0.5', '0.7', '0.9' ) {
			my $dir = "$baseDir/$type/$numparticles/theta$theta";
			print("Running $dir/testdisk.sbatch\n");
			&execute("sbatch $dir/testdisk.sbatch >> sbatch.$$.log");
		}
	}
}

sub execute {
	my $prog = shift;
	croak 'Must specify program name.' unless defined $prog;
	system($prog);
	croak "\n\nError executing \n\t'$prog'\n\n"
	  if ( ( $? >> 8 ) != 0 || $? == -1 || ( $? & 127 ) != 0 );
}
