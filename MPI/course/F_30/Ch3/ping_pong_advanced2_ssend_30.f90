PROGRAM pingpong

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
! Purpose: A program to try MPI_Ssend and MPI_Recv.            !
!                                                              !
! Contents: F-Source                                           !
!                                                              !
!==============================================================!

  USE mpi_f08

  IMPLICIT NONE

  INTEGER proc_a
  PARAMETER(proc_a=0)
            
  INTEGER proc_b
  PARAMETER(proc_b=1)                

  INTEGER ping
  PARAMETER(ping=17)
        
  INTEGER pong
  PARAMETER(pong=23)        

  INTEGER number_of_messages 
  PARAMETER (number_of_messages=50)

  INTEGER start_length 
  PARAMETER (start_length=8)

  INTEGER length_factor 
  PARAMETER (length_factor=64)

  INTEGER max_length                ! 2 Mega 
  PARAMETER (max_length=2097152)

  INTEGER number_package_sizes 
  PARAMETER (number_package_sizes=4)

  INTEGER i, j
  INTEGER(KIND=MPI_ADDRESS_KIND) lb, size_of_real

  INTEGER length
 
  DOUBLE PRECISION start, finish, time, transfer_time
  TYPE(MPI_Status) status
   
  REAL buffer(max_length)

  INTEGER my_rank, size


  CALL MPI_Init()

  CALL MPI_Comm_rank(MPI_COMM_WORLD, my_rank)
  CALL MPI_Type_get_extent(MPI_REAL, lb, size_of_real) 

  IF (my_rank .EQ. proc_a) THEN
     WRITE (*,*) "message size   transfertime    bandwidth"
  END IF

  length = start_length

  DO j = 1, number_package_sizes

     IF (my_rank .EQ. proc_a) THEN
           CALL MPI_Ssend(buffer, length, MPI_REAL, proc_b, ping, MPI_COMM_WORLD)
           CALL MPI_Recv(buffer, length, MPI_REAL, proc_b, pong, MPI_COMM_WORLD, status)
     ELSE IF (my_rank .EQ. proc_b) THEN
           CALL MPI_Recv(buffer, length, MPI_REAL, proc_a, ping, MPI_COMM_WORLD, status)
           CALL MPI_Ssend(buffer, length, MPI_REAL, proc_a, pong, MPI_COMM_WORLD)
     END IF
     
     start = MPI_Wtime()
     
     DO i = 1, number_of_messages
     
        IF (my_rank .EQ. proc_a) THEN
           CALL MPI_Ssend(buffer, length, MPI_REAL, proc_b, ping, MPI_COMM_WORLD)
           CALL MPI_Recv(buffer, length, MPI_REAL, proc_b, pong, MPI_COMM_WORLD, status)
        ELSE IF (my_rank .EQ. proc_b) THEN
           CALL MPI_Recv(buffer, length, MPI_REAL, proc_a, ping, MPI_COMM_WORLD, status)
           CALL MPI_Ssend(buffer, length, MPI_REAL, proc_a, pong, MPI_COMM_WORLD)
        END IF
     
     END DO
     
     finish = MPI_Wtime()
     
     IF (my_rank .EQ. proc_a) THEN
     
        time = finish - start
        transfer_time = time / (2 * number_of_messages)
     
        WRITE(*,*) INT(length*size_of_real),'bytes  ', transfer_time*1e6,'usec  ', 1e-6*length*size_of_real/transfer_time,'MB/s'
     
     END IF

     length = length * length_factor

  END DO

  CALL MPI_Finalize()

END PROGRAM
