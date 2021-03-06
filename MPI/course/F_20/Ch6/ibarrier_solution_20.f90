PROGRAM ibarrier

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
! Authors: Rolf Rabenseifner (HLRS)                            !
!                                                              !
! Contact: rabenseifner@hlrs.de                                !
!                                                              !
! Purpose: A program to try MPI_Ibarrier.                      !
!                                                              !
! Contents: C-Source                                           !
!                                                              !
!**************************************************************!


  USE mpi

  IMPLICIT NONE

  INTEGER :: ierror, my_rank, size
! ...in the role as sending process
  INTEGER :: snd_buf_A, snd_buf_B, snd_buf_C, snd_buf_D
  INTEGER :: dest, number_of_dests=0
  LOGICAL :: snd_finished=.FALSE.
  INTEGER :: snd_rq(0:3)
  INTEGER :: total_number_of_dests ! only for verification, should be removed in real applications 
                                   ! Caution: total_number_of_dests may be less than 4, see IF-statements below
! ...in the role as receiving process
  INTEGER :: rcv_buf
  INTEGER :: ib_rq
  LOGICAL :: ib_finished=.FALSE., rcv_flag
  INTEGER :: rcv_sts(MPI_STATUS_SIZE)
  INTEGER :: number_of_recvs=0, total_number_of_recvs ! only for verification, should be removed in real applications

  INTEGER :: round=0 ! only for verification, should be removed in real applications

  CALL MPI_INIT(ierror)
  CALL MPI_COMM_RANK(MPI_COMM_WORLD, my_rank, ierror)
  CALL MPI_COMM_SIZE(MPI_COMM_WORLD, size, ierror)

! ...in the role as sending process
  dest = my_rank+1
  IF ((dest>=0) .AND. (dest<size)) THEN
    snd_buf_A = 1000*my_rank + dest   ! must not be modified until send-completion with TEST or WAIT 
    CALL MPI_ISSEND(snd_buf_A,1,MPI_INTEGER, dest,222,MPI_COMM_WORLD, snd_rq(number_of_dests), ierror)
    write(*,'(''A rank: '',I3,'' - sending_: message '',I6.6,'' from '',I3,'' to '',I3)') my_rank, snd_buf_A, my_rank, dest
    number_of_dests = number_of_dests + 1
  END IF
  dest = my_rank-2
  IF ((dest>=0) .AND. (dest<size)) THEN
    snd_buf_B = 1000*my_rank + dest   ! must not be modified until send-completion with TEST or WAIT 
    CALL MPI_ISSEND(snd_buf_B,1,MPI_INTEGER, dest,222,MPI_COMM_WORLD, snd_rq(number_of_dests), ierror)
    write(*,'(''A rank: '',I3,'' - sending_: message '',I6.6,'' from '',I3,'' to '',I3)') my_rank, snd_buf_B, my_rank, dest
    number_of_dests = number_of_dests + 1
  END IF
  dest = my_rank+4
  IF ((dest>=0) .AND. (dest<size)) THEN
    snd_buf_C = 1000*my_rank + dest   ! must not be modified until send-completion with TEST or WAIT 
    CALL MPI_ISSEND(snd_buf_C,1,MPI_INTEGER, dest,222,MPI_COMM_WORLD, snd_rq(number_of_dests), ierror)
    write(*,'(''A rank: '',I3,'' - sending_: message '',I6.6,'' from '',I3,'' to '',I3)') my_rank, snd_buf_C, my_rank, dest
    number_of_dests = number_of_dests + 1
  END IF
  dest = my_rank-7
  IF ((dest>=0) .AND. (dest<size)) THEN
    snd_buf_D = 1000*my_rank + dest   ! must not be modified until send-completion with TEST or WAIT 
    CALL MPI_ISSEND(snd_buf_D,1,MPI_INTEGER, dest,222,MPI_COMM_WORLD, snd_rq(number_of_dests), ierror)
    write(*,'(''A rank: '',I3,'' - sending_: message '',I6.6,'' from '',I3,'' to '',I3)') my_rank, snd_buf_D, my_rank, dest
    number_of_dests = number_of_dests + 1
  END IF
  DO WHILE(.NOT. ib_finished)
!   ...in the role as receiving process
!       MPI_IPROBE(MPI_ANY_SOURCE); If there is a message then MPI_RECV for this one message:
        CALL MPI_IPROBE(MPI_ANY_SOURCE,222,MPI_COMM_WORLD, rcv_flag, MPI_STATUS_IGNORE, ierror) 
        IF(rcv_flag) THEN
          CALL MPI_RECV(rcv_buf,1,MPI_INTEGER, MPI_ANY_SOURCE,222,MPI_COMM_WORLD, rcv_sts, ierror)
          write(*,'(''A rank: '',I3,'' - received: message '',I6.6,'' from '',I3,'' to '',I3)') &
&                            my_rank,                     rcv_buf, rcv_sts(MPI_SOURCE), my_rank
          number_of_recvs = number_of_recvs + 1  ! only for verification, should be removed in real applications
        END IF
!   ...in the role as sending process:
!      The following lines make only sense as long as not all MPI_ISSENDs are finished.
    IF(.NOT. snd_finished) THEN
      ! Check whether all MPI_ISSENDs are finished
      CALL MPI_TESTALL(number_of_dests, snd_rq, snd_finished, MPI_STATUSES_IGNORE, ierror)
      ! if all MPI_ISSENDs are finished then call MPI_IBARRIER
      IF(snd_finished) THEN   ! ...i.e., the first time, i.e., only once
        CALL MPI_IBARRIER(MPI_COMM_WORLD, ib_rq, ierror)
      END IF
    END IF
!   ...loop until MPI_IBARRIER finished (i.e. all processes signaled that all receives are called)
    IF(snd_finished) THEN ! the test whether the MPI_IBARRIER is finished
                          ! can be done only if MPI_IBARRIER is already started.
                          ! This ist true as soon snd_finished is true
      CALL MPI_TEST(ib_rq, ib_finished, MPI_STATUS_IGNORE, ierror)
    END IF
  END DO

  ! only for verification, should be removed in real applications:
  CALL MPI_REDUCE(number_of_dests, total_number_of_dests, 1, MPI_INTEGER, MPI_SUM, 0, MPI_COMM_WORLD, ierror)
  CALL MPI_REDUCE(number_of_recvs, total_number_of_recvs, 1, MPI_INTEGER, MPI_SUM, 0, MPI_COMM_WORLD, ierror)
  IF (my_rank .EQ. 0) THEN
    write(*,'(''B #sends= '',I5,''  /  #receives= '',I5)') total_number_of_dests, total_number_of_recvs
    IF (total_number_of_dests .NE. total_number_of_recvs) THEN
      write(*,'(''C ERROR !!!! Wrong number of receives'')')
    END IF
  END IF

  CALL MPI_FINALIZE(ierror)

END PROGRAM
