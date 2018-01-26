# ChaNGa::test

A tool for automating building Charm++ and ChaNGa

### Usage

	build [options]
	 
	 Options:
	   --prefix             Base directory for the source and build directories (default: pwd)
	   --charm-dir=PATH     Charm directory (default: prefix/charm)
	   --changa-dir=PATH    ChaNGa directory (default: prefix/changa)
	   --log-file=FILE      Store logging data in FILE (default: prefix/build.log)
	   --build-dir          Directory where outputs are stored (default: prefix/build)
	   --charm-target=T     Build charm++ for target T (default: netlrts-linux-x86_64)
	   --charm-options=S    Pass options S to charm build (wrap S in quotes to pass many values)
	   --cuda-dir           Override CUDA toolkit directory
	   --build-type         Type of build test to perform (basic, force-test, release)
	   --[no-]cuda          Enable CUDA tests (default: yes)
	   --[no-]smp           Enable SMP tests (default: no)
	   --njobs=N            Number of make jobs (default: N=2)
	   --[no-]fatal-errors  Kill build sequence on any error (default: no; errors are reported only)
	   --help               Print this help message

---

Builds are very chatty. I recommend using

	perl build.pl 1>/dev/null 2>build.err
