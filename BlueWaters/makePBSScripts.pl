use strict;
use warnings;
use Cwd qw(cwd);
#use ChaNGa qw(%launch_config get_all_options);
use Getopt::Long qw(GetOptions);

my %options = (
	'cpu_time' => '00:20:00:00',
	'gpu_time' => '00:12:00:00',
	'total_cores' => 64,
	'acc' => 1,
	'base_dir' => cwd()
);
GetOptions(\%options, 'cpu_time=s', 'gpu_time=s', 'ncores=i', 'acc!', 'base_dir=s') or exit;

my %server_config = (
	'CPU' => {
		'server' 		 => 'xe',
		'time' 			 => $options{'cpu_time'},
		'cores_per_node' => 32,
	},
	'GPU' => {
		'server' 		 => 'xk',
		'time' 			 => $options{'gpu_time'},
		'cores_per_node' => 16
	}
);

#my @perms = get_all_options();
#for my $type (@ChaNGa::types) {
#for my $smp (@ChaNGa::smp) {
#	open my $fdOut, '>', "$type-$smp.pbs" or die;
#	my $modules = ($type eq 'GPU' && $smp eq 'NONSMP') ? "export CRAY_CUDA_MPS=1\n" : '';
#	&print_header($fdOut, $type, $modules);
#for my $o (grep {$_->type eq $type && $_->smp eq $smp} @perms) {
#	&print_commands($fdOut, $o, '');
#	&print_commands($fdOut, $o, 'acc') if $options{'acc'};
#}}}

# make the build script
{
	open my $fdOut, '>', 'build.pbs' or die;
	print $fdOut qq(#!/bin/sh
	
#PBS -l nodes=1:ppn=10:xe
#PBS -l walltime=00:01:30:00
#PBS -e $options{'base_dir'}/src/build.pbs.err
#PBS -o $options{'base_dir'}/src/build.pbs.out
#PBS -M thaines\@astro.wisc.edu
#PBS -m ae

cwd=$options{'base_dir'}
aprun -n 1 -N 1 -d 10 perl -I\$cwd \$cwd/build.pl --release --fatal-errors --charm-target=gni-crayxe --charm-options=hugepages --prefix=\$cwd --build-dir=\$cwd/build --charm-dir=\$cwd/src/charm --changa-dir=\$cwd/src/changa --njobs=10 1>\$cwd/build/build.out 2>\$cwd/build/build.err
);
}

#sub print_commands() {
#	my ($fdOut, $o, $suffix) = @_;
#	
#	my $dir = "$options{'base_dir'}/" . join('/', $o->listify);
#	my $ppn = ($o->is_smp) ? "++ppn " . $o->threads : '';
#	my $pes_per_node = $launch_config{$o->type}{$o->smp}{'pes_per_node'};
#	my $cores_per_pe = $launch_config{$o->type}{$o->smp}{'cores_per_pe'};
#	my $num_nodes = $options{'total_cores'} / $server_config{$o->type}{'cores_per_node'};
#
#	my $total_pes = $num_nodes * $pes_per_node;
#	my $bin_name = "$options{'base_dir'}/src/ChaNGa_" . join('_', $o->type, $o->smp, $o->hexadecapole, $o->simd, $o->prec);
#
#	print $fdOut "aprun -n $total_pes -N $pes_per_node -d $cores_per_pe ",
#				 "$bin_name $ppn $dir/$suffix/params 1>$dir/$suffix/stdout 2>$dir/$suffix/stderr\n";
#}
#
#sub print_header() {
#	my ($fdOut, $type, $modules) = @_;
#	my $cores_per_node = $server_config{$type}{'cores_per_node'};
#	my $server = $server_config{$type}{'server'};
#	my $time = $server_config{$type}{'time'};
#	my $num_nodes = $options{'total_cores'} / $cores_per_node;
#		
#	print $fdOut qq(#!/bin/sh
#
##PBS -l nodes=$num_nodes:ppn=$cores_per_node:$server
##PBS -l walltime=$time
##PBS -e $type/stderr
##PBS -o $type/stdout
##PBS -M thaines\@astro.wisc.edu
##PBS -m ae
#
#export HUGETLB_DEFAULT_PAGE_SIZE=8M
#module load craype-hugepages8M
#$modules
#
#);
#}

