use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'MPI::Simple',
    'VERSION_FROM' => 'Simple.pm',
    'PREREQ_PM' => {Storable => 0},
    'LIBS' => "-lmpi",
    'LD' => 'mpicc',
    'CC' => 'mpicc'
);
