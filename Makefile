MPICC := $(if $(MPICC),$(MPICC),mpicc)

mpi_inc := $(addprefix -I,$(shell $(MPICC) --showme:incdirs))
has_mpi := $(shell $(MPICC) --showme:version || echo "0")

ifeq ($(NO_MPI),1)
	has_mpi := 0
endif

all:
ifneq ($(has_mpi),0)
	@ cp MPI/Simple.mpi.pm MPI/Simple.pm
	@ cd MPI && perl Makefile.PL
	@ cd MPI && make CCFLAGS="-Wall -Wextra $(mpi_inc)"
	@ cp MPI/blib/arch/auto/MPI/Simple/Simple.so MPI/
else
	@ cp MPI/Simple.mock.pm MPI/Simple.pm
endif

clean:
	@ if test -e MPI/Makefile; then cd MPI && make clean; fi
	@ rm -f MPI/Simple.so MPI/Makefile MPI/Makefile.old MPI/Simple.pm

test:
ifneq ($(has_mpi),0)
	@ cd MPI/t && mpiexec -np 2 perl test.pl
else
	@ cd MPI/t && perl test.pl
endif
