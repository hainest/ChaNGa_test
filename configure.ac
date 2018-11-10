AC_PREREQ(2.59)
AC_INIT([ChaNGa::test], [1.0])
AC_CONFIG_SRCDIR([ChaNGa.pm])

AC_ARG_ENABLE([mpi],
	[AS_HELP_STRING([--enable-mpi], [MPI support])],
	[mpi=$enableval], [mpi=no])

HAVE_MPI=no
if test $mpi = "yes"; then
	# Default to the common MPI compiler
	if test -z $MPICC; then
		MPICC=mpicc
	fi
	
	AC_SUBST([MPICC], $MPICC)
	AC_CHECK_PROG(HAVE_MPICC,$MPICC,yes)

	if test x$HAVE_MPICC != xyes; then
		AC_MSG_ERROR([
		MPI requested, but no MPI compiler found (tried $MPICC).
		Try setting MPICC before configuring.
		])
	fi
	HAVE_MPI=yes
fi

AC_SUBST([HAVE_MPI])

AC_CONFIG_FILES([Makefile])
AC_OUTPUT
