#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <mpi.h>
#include <dlfcn.h>

/*
 Finds length of data in stor_ref, sends this to receiver, then
 sends actual data, uses same tag for each message.
 */
void mpi_simple_send(SV* stor_ref, int dest, int tag) {
	int str_len = sv_len(stor_ref);
	MPI_Send(&str_len, 1, MPI_INT, dest, tag, MPI_COMM_WORLD);
	MPI_Send(SvPVX(stor_ref), sv_len(stor_ref), MPI_CHAR, dest, tag, MPI_COMM_WORLD);
}

/*
 Receives int for length of data it should then expect, allocates space
 then receives data into that space.  Creates a new SV and returns it.
 */
SV* mpi_simple_recv(int source, int tag, SV* status) {
	MPI_Status tstatus;
	int len;

	MPI_Recv(&len, 1, MPI_INT, source, tag, MPI_COMM_WORLD, &tstatus);
	char *recv_buf = (char*)malloc((len + 1) * sizeof(char));
	MPI_Recv(recv_buf, len, MPI_CHAR, source, tag, MPI_COMM_WORLD, &tstatus);
	SV* rval = newSVpvn(recv_buf, len);
	sv_setiv(status, tstatus.MPI_SOURCE);
	free(recv_buf);
	return rval;
}

SV* mpi_simple_recv_any(int tag, SV* status) {
	return mpi_simple_recv(MPI_ANY_SOURCE, tag, status);
}

void mpi_simple_init() {
	/* HACKY CRAP
	 *
	 * Reason it's needed: https://www.open-mpi.org/community/lists/users/2015/09/27608.php
	 * Solution: https://bitbucket.org/mpi4py/mpi4py/src/master/src/lib-mpi/compat/openmpi.h?fileviewer=file-view-default#openmpi.h-52
	 */
	dlopen("libmpi.so", RTLD_NOW | RTLD_GLOBAL | RTLD_NOLOAD);

	int is_initialized = 0;
	MPI_Initialized(&is_initialized);
	if (!is_initialized)
		MPI_Init(NULL, NULL);
}
int mpi_simple_comm_rank() {
	int trank;
	MPI_Comm_rank(MPI_COMM_WORLD, &trank);
	return trank;
}
int mpi_simple_comm_size() {
	int tsize;
	MPI_Comm_size(MPI_COMM_WORLD, &tsize);
	return tsize;
}
void mpi_simple_barrier() {
	MPI_Barrier(MPI_COMM_WORLD);
}
void mpi_simple_finalize() {
	int is_initialized = 0;
	MPI_Initialized(&is_initialized);
	if(is_initialized)
		MPI_Finalize();
}

int mpi_simple_error(int error) {
	int global_error = 0;
	MPI_Allreduce(&error, &global_error, 1, MPI_INT, MPI_SUM, MPI_COMM_WORLD);
	return global_error > 0;
}


MODULE = MPI::Simple PACKAGE = MPI::Simple

PROTOTYPES: DISABLE

void
mpi_simple_send (stor_ref, dest, tag)
SV * stor_ref
int dest
int tag

SV *
mpi_simple_recv (source, tag, status)
int source
int tag
SV * status

SV*
mpi_simple_recv_any (tag, status)
int tag
SV* status

void
mpi_simple_init ()

int
mpi_simple_comm_rank ()

int
mpi_simple_comm_size ()

void
mpi_simple_barrier ()

void
mpi_simple_finalize ()

int
mpi_simple_error (error)
int error
