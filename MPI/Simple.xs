#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <mpi.h>
#include <dlfcn.h>

/*
 Finds length of data in stor_ref, sends this to receiver, then
 sends actual data, uses same tag for each message.
 */
int mpi_simple_send(SV* stor_ref, int dest, int tag) {
	int str_len[1];
	str_len[0] = sv_len(stor_ref);
	MPI_Send(str_len, 1, MPI_INT, dest, tag, MPI_COMM_WORLD);
	MPI_Send(SvPVX(stor_ref), sv_len(stor_ref), MPI_CHAR, dest, tag,
	MPI_COMM_WORLD);
	return 0;
}

/*
 Receives int for length of data it should then expect, allocates space
 then receives data into that space.  Creates a new SV and returns it.
 */
SV* mpi_simple_recv(int source, int tag, SV* status) {
	MPI_Status tstatus;
	SV* rval;
	int len_buf[1];
	char *recv_buf;

	MPI_Recv(len_buf, 1, MPI_INT, source, tag, MPI_COMM_WORLD, &tstatus);
	recv_buf = (char*) malloc((len_buf[0] + 1) * sizeof(char));
	if (recv_buf == NULL)
		croak("Allocation error in _Recv");
	MPI_Recv(recv_buf, len_buf[0], MPI_CHAR, source, tag, MPI_COMM_WORLD,
			&tstatus);
	rval = newSVpvn(recv_buf, len_buf[0]);
	sv_setiv(status, tstatus.MPI_SOURCE);
	free(recv_buf);
	return rval;
}

void mpi_simple_init() {
	/* HACKY CRAP
	 *
	 * Reason it's needed: https://www.open-mpi.org/community/lists/users/2015/09/27608.php
	 * Solution: https://bitbucket.org/mpi4py/mpi4py/src/master/src/lib-mpi/compat/openmpi.h?fileviewer=file-view-default#openmpi.h-52
	 */
	dlopen("libmpi.so", RTLD_NOW | RTLD_GLOBAL | RTLD_NOLOAD);

	int flag = 0;
	MPI_Initialized(&flag);
	if (!flag)
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
	MPI_Finalize();
}


MODULE = MPI::Simple PACKAGE = MPI::Simple

PROTOTYPES: DISABLE

int
mpi_simple_send (stor_ref, dest, tag)
SV * stor_ref
int dest
int tag

SV *
mpi_simple_recv (source, tag, status)
int source
int tag
SV * status

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
