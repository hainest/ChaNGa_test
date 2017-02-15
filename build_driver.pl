use strict;
use warnings;
use File::Copy qw(copy);
use Getopt::Long qw(GetOptions);
use ChaNGa qw(execute);
use Cwd qw(cwd);
use Pod::Usage;

my %args = (
	'njobs' 	=> 2,
	'build_dir' => undef,
	'inc_dir' 	=> undef,
	'prefix' 	=> cwd(),
	'charm_dir' => undef,
	'changa_dir'=> undef,
	'help' 		=> 0
);
GetOptions(\%args,
	'njobs=i', 'build_dir=s', 'inc_dir=s',
	'prefix=s', 'charm_dir=s', 'changa_dir=s',
	'help'
) or pod2usage(2);

pod2usage( -exitval => 0, -verbose => 1 ) if $args{'help'};

$args{'inc_dir'} = $args{'prefix'} unless $args{'inc_dir'};
$args{'changa_dir'} = $args{'prefix'} . '/changa' unless $args{'changa_dir'};
$args{'charm_dir'} = $args{'prefix'} . '/charm' unless $args{'charm_dir'};
$args{'build_dir'} = $args{'prefix'} . '/build' unless $args{'build_dir'};


for my $type (@ChaNGa::types) {
for my $smp  (@ChaNGa::smp) {
#	execute(
#		"perl -I$args{'inc_dir'} $args{'prefix'}/build.pl --clean --with-charm=$args{'charm_dir'} " .
#		" $cuda_decode{$type} $smp_decode{$smp} --njobs=$args{'njobs'}"
#	);
for my $hex  (@ChaNGa::hexadecapole) {
for my $simd (@ChaNGa::simd) {
for my $prec (@ChaNGa::precision) {
	next if $prec eq 'single' && $simd eq 'avx';
#	execute(
#		"perl -I$args{'inc_dir'} $args{'prefix'}/build.pl --charm_dir=$args{'charm_dir'} " . 
#		"--changa_dir=$args{'changa_dir'} --clean --no-charm $cuda_decode{$type} " .
#		"$prec_decode{$prec} $hex_decode{$hex} $simd_decode{$simd} --njobs=$args{'njobs'}"
#	);
	my $suffix = "${type}_${smp}_${hex}_${simd}_${prec}";
	copy("$args{'changa_dir'}/ChaNGa", "$args{'build_dir'}/ChaNGa_$suffix");
}}}}}

__END__

=head1 NAME

Build driver for charm++ and ChaNGa

=head1 SYNOPSIS

build_driver.pl [options]

 Options:
   --prefix     Base directory for the source and build directories (default: pwd)
   --build_dir  The build directory (default: prefix/build)
   --inc_dir    Perl include directory (default: prefix)
   --charm_dir  Source directory for charm++ (default: prefix/charm)
   --changa_dir Source directory for ChaNGa (default: prefix/changa)
   --njobs      Number of make jobs (default: 2)
   --help       Print this help message
=cut

