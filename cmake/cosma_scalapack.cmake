# Sets Scalapack variables according to the given type.
# Scalapack type COSMA_SCALAPACK_TYPE can have the following values:
# - Compiler (Default): The compiler add the scalapack flag automatically
#                       therefore no extra link line has to be added.
# - MKL: Uses MKLROOT env. variable or MKL_ROOT variable to find MKL.
#        Only valid if LAPACK Type is set to MKL as well.
#        On Linux systems the type of MPI library used has to be specified
#        using the variable MKL_MPI_TYPE (Default: IntelMPI)
# - Custom: A custom link line has to be specified through COSMA_SCALAPACK_LIB.
# COSMA_HAVE_SCALAPACK is set to ON if scalapack is available, OFF otherwise.
# COSMA_SCALAPACK_LIBRARY provides the generated link line for Scalapack.

include(cosma_utils)
include(CheckFunctionExists)

function(cosma_find_scalapack)
    unset(COSMA_SCALAPACK_LIBRARY CACHE)
    set(COSMA_HAVE_SCALAPACK_INTERNAL OFF)

    setoption(COSMA_SCALAPACK_TYPE STRING "Compiler" "Scalapack setting")
    set_property(CACHE COSMA_SCALAPACK_TYPE PROPERTY STRINGS Compiler MKL Custom)

    if(COSMA_SCALAPACK_TYPE STREQUAL "MKL")
        # Need COSMA_LAPACK_TYPE=MKL
        if(NOT COSMA_LAPACK_TYPE STREQUAL "MKL")
            message(FATAL_ERROR "COSMA_SCALAPACK_TYPE=MKL requires COSMA_LAPACK_TYPE=MKL")
        endif()

        if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
            set(MKL_BLACS_LIB "-lmkl_blacs_mpich_lp64")
        else()
            setoption(MKL_MPI_TYPE STRING "IntelMPI" "MKL MPI support (Linux only) (IntelMPI (compatible with MPICH, ..) or OpenMPI)")
            set_property(CACHE MKL_MPI_TYPE PROPERTY STRINGS "IntelMPI" "OpenMPI")

            if(MKL_MPI_TYPE MATCHES "OpenMPI")
                set(MKL_BLACS_LIB "-lmkl_blacs_openmpi_lp64")
            elseif(MKL_MPI_TYPE MATCHES "IntelMPI")
                set(MKL_BLACS_LIB "-lmkl_blacs_intelmpi_lp64")
            else()
                message(FATAL_ERROR "Unknown MKL MPI Support: ${MKL_MPI_TYPE}")
            endif()
        endif()
        set(COSMA_SCALAPACK_INTERNAL "-lmkl_scalapack_lp64 ${MKL_BLACS_LIB}")

    elseif(COSMA_SCALAPACK_TYPE STREQUAL "Custom")
        setoption(COSMA_SCALAPACK_LIB STRING "" "Scalapack link line for COSMA_SCALAPACK_TYPE = Custom")
        set(COSMA_SCALAPACK_INTERNAL "${COSMA_SCALAPACK_LIB}")
    elseif(COSMA_SCALAPACK_TYPE MATCHES "Compiler")
        set(COSMA_SCALAPACK_INTERNAL "")
    else()
        message(FATAL_ERROR "Unknown Scalapack type: ${COSMA_SCALAPACK_TYPE)}")
    endif()

    separate_arguments(TMP UNIX_COMMAND "${COSMA_SCALAPACK_INTERNAL}")
    set(COSMA_SCALAPACK_LIBRARY "${TMP}" CACHE PATH "Scalapack link line (autogenerated)")

    unset(COSMA_CHECK_LAPACK_INTERNAL CACHE)
    set(CMAKE_REQUIRED_LIBRARIES "${COSMA_LAPACK_LIBRARY}")
    # Check if LAPACK works (i.e. if cosma_find_lapack has been called before).
    CHECK_FUNCTION_EXISTS(dgetrf_ COSMA_CHECK_LAPACK_INTERNAL)
    if (NOT COSMA_CHECK_LAPACK_INTERNAL)
        message(FATAL_ERROR "LAPACK/BLAS not found. FindMKL has to be called before cosma_find_scalapack.")
    endif()
    unset(COSMA_CHECK_LAPACK_INTERNAL CACHE)
    unset(CMAKE_REQUIRED_LIBRARIES)

    unset(COSMA_CHECK_BLACS CACHE)
    unset(COSMA_CHECK_SCALAPACK CACHE)

    set(CMAKE_REQUIRED_LIBRARIES ${COSMA_SCALAPACK_LIBRARY} ${COSMA_LAPACK_LIBRARY})
    # Check if SCALAPACK works
    CHECK_FUNCTION_EXISTS(Cblacs_exit COSMA_CHECK_BLACS)
    CHECK_FUNCTION_EXISTS(pdpotrf_ COSMA_CHECK_SCALAPACK)
    if (NOT COSMA_CHECK_SCALAPACK OR NOT COSMA_CHECK_BLACS)
        message(FATAL_ERROR "Scalapack not found.")
    endif()
    unset(CMAKE_REQUIRED_LIBRARIES)

    set(COSMA_HAVE_SCALAPACK_INTERNAL ON)
    set(COSMA_HAVE_SCALAPACK ${COSMA_HAVE_SCALAPACK_INTERNAL} CACHE BOOL "Scalapack is available (autogenerated)" FORCE)
    if(COSMA_HAVE_SCALAPACK)
        add_definitions(-DCOSMA_HAVE_SCALAPACK)
    endif()

endfunction()
