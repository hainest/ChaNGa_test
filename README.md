# ChaNGa::test

A tool for automating building [Charm++](http://charm.cs.illinois.edu/) and [ChaNGa](http://faculty.washington.edu/trq/hpcc/)

## Getting Started

### Prerequisites

	perl 5.2 or newer
	An MPI-compatible compiler (if you want to use the MPI extensions)

### Installing
For building without MPI, use

	./configure
	make
	make test

If you have MPI installed, then use

	./configure --enable-mpi

If your MPI compiler is named `xxx` rather than `mpicc`, then use

	./configure --enable-mpi MPICC=xxx

If your MPI runner is named `yyy` rather than `mpiexec`, then use

	make test MPIEXEC=yyy

## Usage
The most common usage will be to check that Charm++ and ChaNGa are passing the "basic" build test.

	perl build.pl --charm-target=YYY --build-type=basic --njobs=NN

where YYY is your regular Charm++ build target and NN is the number of make jobs per build to use. See the [Usage](https://github.com/hainest/ChaNGa_test/wiki/Usage) section of the wiki for details.

To run parallel builds, you can use

    mpiexec -np XX perl build.pl --charm-target=YYY --build-type=basic --njobs=NN

Note that the test suite uses MPI to distribute work across the XX MPI ranks in a round-robin fashion and then invokes make with NN jobs on each rank, so you will get XX * NN total threads across all machines.

## Contributing

Pull requests are always welcome!

## License

This project is licensed under the GPL3 License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

This project is based on the following external modules:

* [Parallel::MPI::Simple](https://metacpan.org/pod/Parallel::MPI::Simple) module from Alex Gough
* [Set::CrossProduct](https://metacpan.org/pod/Set::CrossProduct) from brian d foy
* [Try::Tiny](https://metacpan.org/pod/Try::Tiny) from Karen Etheridge
