mpi_inc := $(addprefix -I,$(shell mpicc --showme:incdirs))

all:
	cd MPI && perl Makefile.PL
	cd MPI && make CCFLAGS="-Wall -Wextra $(mpi_inc)"
	cp MPI/blib/arch/auto/MPI/Simple/Simple.so MPI/

clean:
	cd MPI && make clean
	rm -f MPI/Simple.so MPI/Makefile MPI/Makefile.old

test:
	cd MPI/t && mpiexec -np 2 perl test.pl
