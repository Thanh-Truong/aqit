/*****************************************************************************
 * AMOS2
 *
 * Author: (c) 1993 Mikael Pettersson, IDA (extended by Tore Risch)
 * $RCSfile: linh.h,v $
 * $Revision: 1.3 $ $Date: 2012/12/21 11:51:41 $
 * $State: Exp $ $Locker:  $
 *
 * Description: Linear hashing package
 * ===========================================================================
 * $Log: linh.h,v $
 * Revision 1.3  2012/12/21 11:51:41  torer
 * malloc.h removed
 *
 * Revision 1.2  2009/04/07 20:30:52  torer
 * Faster hashing on arrays and lists
 *
 ****************************************************************************/

#ifndef _linh_h_
#define _linh_h_

#include <memory.h>     /* get memcmp() */
#include <string.h>     /* get strdup() */
#include <stdlib.h>
#include <stdio.h>

extern unsigned hash_x33_u4(register char *str, register unsigned int len);

/* SEGMENTSIZE must be a power of 2 !! */
#define LH_SEGMENTSIZE     1024
#define LH_DIRECTORYSIZE   1024

typedef struct element {
    unsigned            len;
    unsigned            hash;
    char                *str;
    char                *value;
    struct element      *next;
} element_t;

typedef struct segment {
    element_t   *elements[LH_SEGMENTSIZE];
} segment_t;

typedef struct hashtable {
    unsigned int p;              /* next bucket to split */
    unsigned int maxp_minus_1;   /* == maxp - 1; maxp is the upper bound */
    int         slack;          /* number of insertions before expansion */
    int hashonaddr;
    segment_t   *directory[LH_DIRECTORYSIZE];
} hashtable_t;

hashtable_t *lh_init_hashtable(int);
typedef int (*maplh_function)(char *,char *,void *);
void lh_map(hashtable_t *T, maplh_function f, void *x);
void lh_enter(char *val, char *str, hashtable_t *T);
char *lh_retrieve(char *str, hashtable_t *T);
char *lh_delete(char *str, hashtable_t *T);
void lh_free(hashtable_t *T);

#endif
