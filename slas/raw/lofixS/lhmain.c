/*****************************************************************************
 * AMOS2
 *
 * Author: (c) 2010 Tore Risch, UDBL
 * $RCSfile: lhmain.c,v $
 * $Revision: 1.1 $ $Date: 2011/01/13 17:36:46 $
 * $State: Exp $ $Locker:  $
 *
 * Description: Linear Hashing index test program
 * ===========================================================================
 * $Log: lhmain.c,v $
 * Revision 1.1  2011/01/13 17:36:46  torer
 * Test program for LH index
 *
 ****************************************************************************/

#define TRUE 1
#define FALSE 0

#include "linh.h"

int lh_mapper(char * key,char * val,void *xa)
{
  (*((int *)xa))++;
  return TRUE; /* To continue iteration */
}

int main(int argc, char **argv)
{
  hashtable_t *ht = lh_init_hashtable(TRUE);
  int i, cnt, size=10000000, k;

  printf("[Populating hash table with %d keys", size);
  for(i=1;i<=size;i++)
    {
      lh_enter((char *)(i+100), (char *)(i), ht);
    }
  printf("]\n");
  k = size/2;
  printf("Value of ht(%d)=%d\n",k,(int)lh_retrieve((char *)(k),ht));
  lh_delete((char *)k, ht);
  printf("Value of deleted ht(%d)=%d\n",k,(int)lh_retrieve((char *)(k),ht));
  printf("[Traversing hash table");
  cnt = 0;
  lh_map(ht, lh_mapper, &cnt);
  printf(" %d keys]\n",cnt);
  return 0;
}
