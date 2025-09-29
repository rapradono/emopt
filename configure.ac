AC_INIT([emopt],[version-0.5])
AC_PREFIX_DEFAULT($HOME/.local)
if test $prefix == NONE
then
	prefix=$HOME/.local
fi

dnl Dependency versions
BOOST_VERSION=1_73_0
PETSC_VERSION=3.23.6
SLEPC_VERSION=3.23.3

dnl check dependencies needed to compile petsc and slepc
AC_LANG([C++])
AC_PROG_CXX

AC_CHECK_PROG(NVCC_CHECK, nvcc, yes)
AC_CHECK_PROG(NVSMI_CHECK, nvidia-smi, yes)
AC_CHECK_PROG(CMAKE_CHECK, cmake, yes)
if test $NVCC_CHECK != "yes"
then
	AC_MSG_ERROR(nvcc not found. Please install cuda)
fi

if test $NVSMI_CHECK != "yes"
then
	AC_MSG_WARN(nvidia-smi not found. Are your Nvidia drivers correctly installed?)
fi

AC_CHECK_HEADERS([mpi.h])
AC_CHECK_HEADERS([Eigen/Core])
AC_CHECK_HEADERS([boost/geometry/geometries/polygon.hpp])

dnl make sure the .local folder exists
AC_CHECK_FILE($prefix, [], [AC_MSG_ERROR(Prefix does not exist.)])
AC_MSG_NOTICE(Dependencies will be installed to $prefix)

dnl setup temp build directory
mkdir build

dnl install Eigen if not already installed
if test $ac_cv_header_Eigen_Core == "no" 
then
	AC_CHECK_FILE($prefix/include/Eigen, [eigen_exists=1], [eigen_exists=0])
	if test $eigen_exists == 0
	then
		AC_MSG_NOTICE(Eigen not found. Installing...)
		EIGEN_VERSION=3.4
		cd build
		git clone https://gitlab.com/libeigen/eigen.git
		cd eigen
		git checkout $EIGEN_VERSION
		mkdir -p $prefix/include
		cp -r Eigen $prefix/include/Eigen
		cd ..
		rm -rf eigen
	else
		AC_MSG_NOTICE(Eigen already installed to prefix. Skipping...)
	fi
fi

dnl install boost if not already installed
if test $ac_cv_header_boost_geometry_geometries_polygon_hpp == "no" 
then
	AC_CHECK_FILE($prefix/include/boost, [boost_exists=1], [boost_exists=0])
	if test $boost_exists == 0
	then
		AC_MSG_NOTICE(Boost geometry not found. Installing...)

		cd build
		BOOST_FILE=boost_$BOOST_VERSION
		curl --output $BOOST_FILE.tar.gz "https://archives.boost.io/release/1.73.0/source/$BOOST_FILE.tar.gz"
		tar xvzf $BOOST_FILE.tar.gz
		
		cd $BOOST_FILE
		./bootstrap.sh
		./b2 headers

		mkdir -p $prefix/include
		cp -r boost $prefix/include/boost
		cd ..
	else
		AC_MSG_NOTICE(Boost geometry already installed to prefix. Skipping...)
	fi
fi

dnl build petsc if not already built
AC_CHECK_FILE($prefix/share/petsc, [petsc_exists=1], [petsc_exists=0])
if test $petsc_exists == 0
then
	AC_MSG_NOTICE(\nPETSc is not installed. Building it now. This may take a while...)
	unset PETSC_DIR
	unset PETSC_ARCH

	cd build
	git clone -b v$PETSC_VERSION https://gitlab.com/petsc/petsc.git petsc
	cd petsc

	dnl compile
	AC_MSG_NOTICE(Compiling PETSc...)
	if test $CMAKE_CHECK != yes
	then
		download_cmake=--download-cmake
	else
		download_cmake=
	fi

	./configure --with-scalar-type=complex --with-mpi=1 --COPTFLAGS='-O3' \
		    --FOPTFLAGS='-O3' --CXXOPTFLAGS='-O3' --with-debugging=0 \
		    --prefix=$prefix --download-scalapack --download-mumps --download-fblaslapack=1 \
		    --download-parmetis --download-metis --download-ptscotch \
		    $download_cmake
	make all
	make install

	cd ..
	rm -r petsc

else
	AC_MSG_NOTICE(PETSc is already installed to prefix. Skipping...)
fi

dnl build petsc if not already built
AC_CHECK_FILE($prefix/share/slepc, [selpc_exists=1], [slepc_exists=0])
if test $slepc_exists == 0
then
	AC_MSG_NOTICE(SLEPc is not installed. Building it now. This may take a while...)
	PETSC_DIR=$prefix
	PETSC_ARCH=
	unset SLEPC_DIR

	cd build

	dnl download SLEPc
	AC_MSG_NOTICE(https://slepc.upv.es/download/distrib/slepc-$SLEPC_VERSION.tar.gz)
	curl --output slepc.tar.gz "https://slepc.upv.es/download/distrib/slepc-$SLEPC_VERSION.tar.gz"
	tar xzf slepc.tar.gz
	cd slepc-$SLEPC_VERSION

	./configure --prefix=$prefix
	make SLEPC_DIR=./ PETSC_DIR=$PETSC_DIR
	make SLEPC_DIR=./ PETSC_DIR=$PETSC_DIR install
	SLEPC_DIR=$prefix
	make SLEPC_DIR=$SLEPC_DIR PETSC_DIR=$PETSC_DIR PETSC_ARCH=$PETSC_ARCH check

	cd ..
	rm -r slepc-$SLEPC_VERSION

else
	AC_MSG_NOTICE(SLEPc is already installed to prefix. Skipping...)
fi

dnl Cleanup
rm -r build

dnl Certain python dependencies for emopt need special treatment
pip install numpy mpi4py
PETSC_DIR=$prefix PETSC_ARCH= pip install petsc4py==$PETSC_VERSION
SLEPC_DIR=$prefix PETSC_DIR=$prefix PETSC_ARCH= pip install slepc4py==$SLEPC_VERSION

dnl output Makefile
AC_SUBST(EIGEN_DIR, [$prefix/include])
AC_SUBST(BOOST_DIR, [$prefix/include])

AC_CONFIG_FILES([src/Makefile])
AC_OUTPUT
