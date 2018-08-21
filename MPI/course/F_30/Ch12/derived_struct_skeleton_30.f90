PROGRAM ring_derived

!==============================================================!
!                                                              !
! This file has been written as a sample solution to an        !
! exercise in a course given at the High Performance           !
! Computing Centre Stuttgart (HLRS).                           !
! The examples are based on the examples in the MPI course of  !
! the Edinburgh Parallel Computing Centre (EPCC).              !
! It is made freely available with the understanding that      !
! every copy of this file must include this header and that    !
! HLRS and EPCC take no responsibility for the use of the      !
! enclosed teaching material.                                  !
!                                                              !
! Authors: Joel Malard, Alan Simpson,            (EPCC)        !
!          Rolf Rabenseifner, Traugott Streicher (HLRS)        !
!                                                              !
! Contact: rabenseifner@hlrs.de                                !
!                                                              !
! Purpose: A program that uses derived data-types.             !
!                                                              !
! Contents: F-Source                                           !
!                                                              !
!==============================================================!

  USE mpi_f08

  IMPLICIT NONE

  INTEGER, PARAMETER :: to_right=201

  INTEGER :: my_rank, size

  INTEGER :: right, left

  INTEGER :: i

  TYPE t
     SEQUENCE
     INTEGER :: ___    ! PLEASE SUBSTITUTE ALL SKELETON CODE: ____ 
     REAL    :: ___
  END TYPE t
  TYPE(t), ASYNCHRONOUS :: snd_buf
  TYPE(t) :: rcv_buf, sum

  INTEGER(KIND=MPI_ADDRESS_KIND) :: first_var_address, second_var_address
  TYPE(MPI_Datatype) :: send_recv_type

  INTEGER :: array_of_block_length(2)
  TYPE(MPI_Datatype) :: array_of_types(2)
  INTEGER(KIND=MPI_ADDRESS_KIND) :: array_of_displacements(2)

  TYPE(MPI_Status) :: status

  TYPE(MPI_Request) :: request

  INTEGER(KIND=MPI_ADDRESS_KIND) :: iadummy


  CALL MPI_Init()

  CALL MPI_Comm_rank(MPI_COMM_WORLD, my_rank)
  CALL MPI_Comm_size(MPI_COMM_WORLD, size)

  right = mod(my_rank+1,      size)
  left  = mod(my_rank-1+size, size)
!     ... this SPMD-style neighbor computation with modulo has the same meaning as:
!     right = my_rank + 1
!     IF (right .EQ. size) right = 0
!     left = my_rank - 1
!     IF (left .EQ. -1) left = size-1

! Create derived datatype. 

  array_of_block_length(1) = ___
  array_of_block_length(2) = ___

  array_of_types(1) = ___
  array_of_types(2) = ___

  CALL MPI_Get_address(snd_buf%___, first_var_address)
  CALL MPI_Get_address(snd_buf%___, second_var_address)

  array_of_displacements(1) = 0
  array_of_displacements(2) = ___

  CALL MPI_Type_create_struct(___ ... ___, send_recv_type)
  CALL MPI_Type_commit(___)

! ---------- original source code from MPI/course/F_30/Ch4/ring_30.f90 - PLEASE MODIFY: 
  sum = 0
  snd_buf = my_rank

  DO i = 1, size

     CALL MPI_Issend(snd_buf, 1, MPI_INTEGER, right, to_right, MPI_COMM_WORLD, request)

     CALL MPI_Recv(rcv_buf, 1, MPI_INTEGER, left, to_right, MPI_COMM_WORLD, status)

     CALL MPI_Wait(request, status)

!    CALL MPI_GET_ADDRESS(snd_buf, iadummy)
!    ... should be substituted as soon as possible by:
     IF (.NOT.MPI_ASYNC_PROTECTS_NONBLOCKING) CALL MPI_F_sync_reg(snd_buf)

     snd_buf = rcv_buf
     sum = sum + rcv_buf

  END DO

  WRITE(*,*) "PE", my_rank, ": Sum =", sum

  CALL MPI_Finalize()

END PROGRAM
