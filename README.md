# ChaNGa::test

A tool for automating building Charm++ and ChaNGa

### Usage

	build [options]
	 
	 Options:
	   --prefix             Base directory for the source and build directories (default: pwd)
	   --charm-dir=PATH     Charm source directory (default: prefix/charm)
	   --changa-dir=PATH    ChaNGa source directory (default: prefix/changa)
	   --log-file=FILE      Store logging data in FILE (default: prefix/build.log)
	   --build-dir          Directory where outputs are stored (default: prefix/build)
	   --charm-target=T     Build charm++ for target T (default: netlrts-linux-x86_64)
	   --charm-options=S    Pass options S to charm build (wrap S in quotes to pass many values)
	   --cuda-dir           Override CUDA toolkit directory
	   --build-type         Type of build test to perform (default, basic, force-test, release)
	   --[no-]cuda          Enable CUDA tests (default: yes)
	   --[no-]smp           Enable SMP tests (default: no)
	   --[no-]projections   Enable Projections tests (default: no)
	   --njobs=N            Number of make jobs (default: N=2)
	   --[no-]fatal-errors  Kill build sequence on any error (default: no; errors are reported only)
	   --[no-]charm         Build the Charm++ libraries for ChaNGa (default: yes)
	   --[no-]changa        Build ChaNGa (default: yes)
	   --help               Print this help message

In addition to the predefined build types (basic, force-test, and release), you can specify a
comma-separated list of configure targets to build. For example,

	build.pl --build-type=hexadecapole,float
	
will test the HEXADECAPOLE and COSMO_FLOAT options (note: CUDA is still enabled here; to disable, use `--no-cuda`). 
