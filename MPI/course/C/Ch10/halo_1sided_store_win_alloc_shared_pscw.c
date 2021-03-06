/****************************************************************
 *                                                              *
 * This file has been written as a sample solution to an        *
 * exercise in a course given at the High Performance           *
 * Computing Centre Stuttgart (HLRS).                           *
 * The examples are based on the examples in the MPI course of  *
 * the Edinburgh Parallel Computing Centre (EPCC).              *
 * It is made freely available with the understanding that      *
 * every copy of this file must include this header and that    *
 * HLRS and EPCC take no responsibility for the use of the      *
 * enclosed teaching material.                                  *
 *                                                              *
 * Authors: Joel Malard, Alan Simpson,            (EPCC)        *
 *          Rolf Rabenseifner, Traugott Streicher (HLRS)        *
 *                                                              *
 * Contact: rabenseifner@hlrs.de                                * 
 *                                                              *  
 * Purpose: A program to meassure 1-dim halo communication      *
 *          in myrank -1 and +1 directions (left and right)     *
 *                                                              *
 * Contents: C-Source                                           *
 *                                                              *
 ****************************************************************/


#include <stdio.h>
#include <mpi.h>

#define number_of_messages 50
#define start_length 4
#define length_factor 8
#define max_length 8388608 /* ==> 2 x 32 MB per process */
#define number_package_sizes 8
/* #define max_length 67108864    */ /* ==> 2 x 0.5 GB per process */
/* #define number_package_sizes 9 */

int main(int argc, char *argv[])
{
  int i, j, k, length, my_rank, left, right, size, test_value, mid;    
  double start, finish, transfer_time; 
  float snd_buf_left[max_length], snd_buf_right[max_length];
  float *rcv_buf_left, *rcv_buf_right;

  MPI_Win win_rcv_buf_left, win_rcv_buf_right;
  int offset_left, offset_right;
  MPI_Comm comm_sm; int size_comm_sm;

  MPI_Group grp_world, grp_left, grp_right;

/* Naming conventions                                                                */
/* Processes:                                                                        */
/*     my_rank-1                        my_rank                         my_rank+1    */
/* "left neighbor"                     "myself"                     "right neighbor" */
/*   ...    rcv_buf_right <--- snd_buf_left snd_buf_right ---> rcv_buf_left    ...   */
/*   ... snd_buf_right ---> rcv_buf_left       rcv_buf_right <--- snd_buf_left ...   */
/*                        |                                  |                       */
/*              halo-communication                 halo-communication                */

  MPI_Init(&argc, &argv);
  MPI_Comm_rank(MPI_COMM_WORLD, &my_rank);
  MPI_Comm_size(MPI_COMM_WORLD, &size);
  right = (my_rank+1)      % size;
  left  = (my_rank-1+size) % size;

/* ... Get nearest neighbour ranks as groups */

  MPI_Comm_group(MPI_COMM_WORLD, &grp_world);
  MPI_Group_incl(grp_world, 1, &left,  &grp_left);
  MPI_Group_incl(grp_world, 1, &right, &grp_right);
  MPI_Group_free(&grp_world);

  MPI_Comm_split_type(MPI_COMM_WORLD, MPI_COMM_TYPE_SHARED, 0, MPI_INFO_NULL, &comm_sm);
  MPI_Comm_size(comm_sm, &size_comm_sm); 
  if (size_comm_sm != size) { printf("Not on one shared memory node \n"); MPI_Abort(MPI_COMM_WORLD, 0); }

  /* ParaStation MPI may no allow MPI_Win_allocate_shared on MPI_COMM_WORLD. Workaround: Substitute MPI_COMM_WORLD by comm_sm (on 2 lines): */ 
  MPI_Win_allocate_shared((MPI_Aint)(max_length*sizeof(float)), sizeof(float), MPI_INFO_NULL, MPI_COMM_WORLD, &rcv_buf_left,  &win_rcv_buf_left );
  MPI_Win_allocate_shared((MPI_Aint)(max_length*sizeof(float)), sizeof(float), MPI_INFO_NULL, MPI_COMM_WORLD, &rcv_buf_right, &win_rcv_buf_right);

/*offset_left  is defined so that rcv_buf_left(xxx+offset_left) in process 'my_rank' is the same location as */
/*                                rcv_buf_left(xxx) in process 'left':                                       */
  offset_left  = +(left-my_rank)*max_length;

/*offset_right is defined so that rcv_buf_right(xxx+offset_right) in process 'my_rank' is the same location as */
/*                                rcv_buf_right(xxx) in process 'right':                                       */
  offset_right  = +(right-my_rank)*max_length;

  if (my_rank == 0) printf("    message size      transfertime  duplex bandwidth per process and neighbor\n");

  length = start_length;

  for (j = 1; j <= number_package_sizes; j++)
  { 
    
    for (i = 0; i <= number_of_messages; i++)
    {
      if(i==1) start = MPI_Wtime();

      test_value = j*1000000 + i*10000 + my_rank*10 ; mid = (length-1)/number_of_messages*i;

      snd_buf_left[0]=test_value+1  ; snd_buf_left[mid]=test_value+2  ; snd_buf_left[length-1]=test_value+3;
      snd_buf_right[0]=test_value+6 ; snd_buf_right[mid]=test_value+7 ; snd_buf_right[length-1]=test_value+8;

      MPI_Win_post (grp_left,  /*workaround: no assertions:*/ 0, win_rcv_buf_left);
      MPI_Win_post (grp_right, /*workaround: no assertions:*/ 0, win_rcv_buf_right);
      MPI_Win_start(grp_right, /*workaround: no assertions:*/ 0, win_rcv_buf_left);
      MPI_Win_start(grp_left,  /*workaround: no assertions:*/ 0, win_rcv_buf_right);

/*    MPI_Put(snd_buf_left,  length, MPI_FLOAT, left,  (MPI_Aint)0, length, MPI_FLOAT, win_rcv_buf_right); */
/*    MPI_Put(snd_buf_right, length, MPI_FLOAT, right, (MPI_Aint)0, length, MPI_FLOAT, win_rcv_buf_left ); */
/*      ... is substited by: */
      for(k=0; k<length; k++) rcv_buf_right[k+offset_left]  = snd_buf_left [k];
      for(k=0; k<length; k++) rcv_buf_left [k+offset_right] = snd_buf_right[k];

      MPI_Win_complete(win_rcv_buf_left );
      MPI_Win_complete(win_rcv_buf_right);
      MPI_Win_wait    (win_rcv_buf_left);
      MPI_Win_wait    (win_rcv_buf_right);

/*    ...snd_buf_... is used to store the values that were stored in snd_buf_... in the neighbor process */
      test_value = j*1000000 + i*10000 + left*10  ; mid = (length-1)/number_of_messages*i;
      snd_buf_right[0]=test_value+6 ; snd_buf_right[mid]=test_value+7 ; snd_buf_right[length-1]=test_value+8;
      test_value = j*1000000 + i*10000 + right*10 ; mid = (length-1)/number_of_messages*i;
      snd_buf_left[0]=test_value+1  ; snd_buf_left[mid]=test_value+2  ; snd_buf_left[length-1]=test_value+3;
      if ((rcv_buf_left[0] != snd_buf_right[0]) || (rcv_buf_left[mid] != snd_buf_right[mid]) || 
                                                   (rcv_buf_left[length-1] != snd_buf_right[length-1])) {
         printf("%d: j=%d, i=%d --> snd_buf_right[0,%d,%d]=(%f,%f,%f)\n",
                    my_rank, j, i, mid, length-1, snd_buf_right[0], snd_buf_right[mid], snd_buf_right[length-1]);
         printf("%d:     is not identical to rcv_buf_left[0,%d,%d]=(%f,%f,%f)\n",
                    my_rank,       mid, length-1, rcv_buf_left[0],  rcv_buf_left[mid],  rcv_buf_left[length-1]);
      }
      if ((rcv_buf_right[0] != snd_buf_left[0]) || (rcv_buf_right[mid] != snd_buf_left[mid]) ||
                                                   (rcv_buf_right[length-1] != snd_buf_left[length-1])) {
         printf("%d: j=%d, i=%d --> snd_buf_left[0,%d,%d]=(%f,%f,%f)\n",
                    my_rank, j, i, mid, length-1, snd_buf_left[0],  snd_buf_left[mid],  snd_buf_left[length-1]);
         printf("%d:     is not identical to rcv_buf_right[0,%d,%d]=(%f,%f,%f)\n",
                    my_rank,       mid, length-1, rcv_buf_right[0], rcv_buf_right[mid], rcv_buf_right[length-1]);
      }

    }
    finish = MPI_Wtime();

    if (my_rank == 0) 
    {
      transfer_time = (finish - start) / number_of_messages;
      printf("%10i bytes %12.3f usec %13.3f MB/s\n", 
             length*(int)sizeof(float), transfer_time*1e6, 1.0e-6*2*length*sizeof(float) / transfer_time);
    }

    length = length * length_factor;
  }
  MPI_Win_free(&win_rcv_buf_left );
  MPI_Win_free(&win_rcv_buf_right);

  MPI_Finalize();
}
