PROGRAM ring

!**************************************************************!
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
! Purpose: A program to try MPI_Issend and MPI_Recv.           !
!                                                              !
! Contents: C-Source                                           !
!                                                              !
!**************************************************************!


  USE mpi_f08

  IMPLICIT NONE

  INTEGER, PARAMETER :: to_right=201

  INTEGER :: my_world_rank, world_size, my_sub_rank, sub_size
  INTEGER :: snd_buf, rcv_buf
  INTEGER :: right, left
  INTEGER :: sumA, sumB, i
  INTEGER :: mycolor
  TYPE(MPI_Comm ) :: sub_comm

  TYPE(MPI_Status ) :: status
  TYPE(MPI_Request) :: request


  CALL MPI_Init()

  CALL MPI_Comm_size(MPI_COMM_WORLD, world_size)
  CALL MPI_Comm_rank(MPI_COMM_WORLD, my_world_rank)

  IF (my_world_rank > (world_size-1)/3) THEN
    mycolor = 1
  ELSE
    mycolor = 0
  END IF
  ! This definition of mycolor implies that the first color is 0
  !  --> see calculation of remote_leader below 

  CALL MPI_Comm_split(MPI_COMM_WORLD, mycolor, 0, sub_comm) 
  CALL MPI_Comm_size(sub_comm, sub_size)
  CALL MPI_Comm_rank(sub_comm, my_sub_rank)

  right = mod(my_sub_rank+1,          sub_size)
  left  = mod(my_sub_rank-1+sub_size, sub_size)
! ... this SPMD-style neighbor computation with modulo has the same meaning as: 
! right = my_sub_rank + 1          
! IF (right .EQ. sub_size) right = 0 
! left = my_sub_rank - 1           
! IF (left .EQ. -1) left = sub_size-1

  sumA = 0
  snd_buf = my_world_rank
  DO I = 1, sub_size
    CALL MPI_Issend(snd_buf, 1, MPI_INTEGER, right, to_right, sub_comm, request)
    CALL MPI_Recv(rcv_buf, 1, MPI_INTEGER, left, to_right, sub_comm, status)
    CALL MPI_Wait(request, status)
    snd_buf = rcv_buf
    sumA = sumA + rcv_buf
  END DO

  sumB = 0
  snd_buf = my_sub_rank
  DO I = 1, sub_size
    CALL MPI_Issend(snd_buf, 1, MPI_INTEGER, right, to_right, sub_comm, request)
    CALL MPI_Recv(rcv_buf, 1, MPI_INTEGER, left, to_right, sub_comm, status)
    CALL MPI_Wait(request, status)
    snd_buf = rcv_buf
    sumB = sumB + rcv_buf
  END DO

  write(*,'(''PE world:'',I3,'', color='',I3,'' sub:'',I3,'' SumA='',I5,'' SumB='',I5)')&
  &           my_world_rank,     mycolor,    my_sub_rank,    sumA,         sumB

  CALL MPI_Finalize()
END PROGRAM
