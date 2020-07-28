/*****************************************************************************
 * AMOS2
 *
 * Author: (c) 1993 Mikael Pettersson, IDA (extended by Tore Risch)
 * $Revision:
 * $State:
 *
 * Description: Linear hashing package
 *
 * Requirements:
 * ===========================================================================
 * $Log:
 */

#include "linh.h"

void *lh_malloc(int bytes)
{
   void *res;

   res = malloc(bytes);
   if(res==NULL)
   {
     fprintf(stderr, "Out of memory\n");
     exit(1);
   }
   return res;
}

/* The `hash_x33' function unrolled four times. */

unsigned hash_x33_u4(register char *str, register unsigned int len)
{
    register unsigned int h = 0;

    for(; len >= 4; len -= 4) {
        h = (h << 5) + h + *str++;
        h = (h << 5) + h + *str++;
        h = (h << 5) + h + *str++;
        h = (h << 5) + h + *str++;
    }
    switch( len ) {
      case 3:
        h = (h << 5) + h + *str++;
        /*FALLTHROUGH*/
      case 2:
        h = (h << 5) + h + *str++;
        /*FALLTHROUGH*/
      case 1:
        h = (h << 5) + h + *str++;
        break;
      default:  /*case 0:*/
        break;
    }
    return h;
}
#define HASH(str,len)   hash_x33_u4((str),(len))

#define DIRINDEX(address)       ((address) / LH_SEGMENTSIZE)
#define SEGINDEX(address)       ((address) % LH_SEGMENTSIZE)
#if     !defined(MAXLOADFCTR)
#define MAXLOADFCTR     2
#endif  /*MAXLOADFCTR*/
#if     !defined(MINLOADFCTR)
#define MINLOADFCTR     (MAXLOADFCTR/2)
#endif  /*MINLOADFCTR*/

#define new_element()   (element_t*)lh_malloc(sizeof(element_t))

segment_t *new_lh_segment(void)
{
   segment_t *nw = (segment_t*)lh_malloc(sizeof(segment_t));
   int i;

   for(i=0;i<LH_SEGMENTSIZE;i++)
   {
       nw->elements[i]=NULL;
   }
   return nw;
}

/* initialize the hash table `T' */

hashtable_t *lh_init_hashtable(int hashonaddr)
{
    hashtable_t *T;

    T = (hashtable_t *)lh_malloc(sizeof(*T));
    T->p                = 0;
    T->maxp_minus_1     = LH_SEGMENTSIZE - 1;
    T->slack            = LH_SEGMENTSIZE * MAXLOADFCTR;
    T->directory[0]     = new_lh_segment();
    T->hashonaddr = hashonaddr;
    {   /* the first segment must be entirely cleared before used */
        element_t **p = &T->directory[0]->elements[0];
        int count = LH_SEGMENTSIZE;
        do {
            *p++ = (element_t*)0;
        } while( --count > 0 );
    }
    {   /* clear the rest of the directory */
        segment_t **p = &T->directory[1];
        int count = LH_DIRECTORYSIZE - 1;
        do {
            *p++ = (segment_t*)0;
        } while( --count > 0 );
    }
    return T;
}

void lh_expandtable(hashtable_t *T)
{
    element_t **oldbucketp, *chain, *headofold, *headofnew, *next;
    unsigned maxp0 = T->maxp_minus_1 + 1;
    unsigned newaddress = maxp0 + T->p;

    /* no more room? */
    if( newaddress >= LH_DIRECTORYSIZE * LH_SEGMENTSIZE )
        return; /* should allocate a larger directory */

    /* if necessary, create a new segment */
    if( SEGINDEX(newaddress) == 0 )
        T->directory[DIRINDEX(newaddress)] = new_lh_segment();

    /* locate the old (to be split) bucket */
    oldbucketp = &T->directory[DIRINDEX(T->p)]->elements[SEGINDEX(T->p)];

    /* adjust the state variables */
    if( ++(T->p) > T->maxp_minus_1 ) {
        T->maxp_minus_1 = 2 * T->maxp_minus_1 + 1;
        T->p = 0;
    }
    T->slack += MAXLOADFCTR;

    /* relocate records to the new bucket (does not preserve order) */
    headofold = (element_t*)0;
    headofnew = (element_t*)0;
    for(chain = *oldbucketp; chain != (element_t*)0; chain = next) {
        next = chain->next;
        if( chain->hash & maxp0 ) {
            chain->next = headofnew;
            headofnew = chain;
        } else {
            chain->next = headofold;
            headofold = chain;
        }
    }
    *oldbucketp = headofold;
    T->directory[DIRINDEX(newaddress)]->elements[SEGINDEX(newaddress)]
            = headofnew;
}

/* insert string `str' with `len' characters in table `T' */

void lh_enter(char *val, char *str, hashtable_t *T)
{
    unsigned hash, address;
    element_t **chainp, *chain;
    unsigned int len;
    int hashonaddr = T->hashonaddr;

    /* locate the bucket for this string */
    if(hashonaddr) {hash = (unsigned int)str; len = sizeof(int);}
    else {len= 1 + strlen(str); hash = HASH(str, len); }
    address = hash & T->maxp_minus_1;
    if( address < T->p ) address = hash & (2 * T->maxp_minus_1 + 1);

    chainp = &T->directory[DIRINDEX(address)]->elements[SEGINDEX(address)];

    /* is the string already in the hash table? */
    for(chain = *chainp; chain != (element_t*)0; chain = chain->next)
    {
        if(hashonaddr)
        {
           if(chain->hash == hash && chain->str == str)
           {
              chain->value = val;
              return;
           }
        }
        else if( chain->hash == hash &&
                 chain->len == len &&
                 !memcmp(chain->str, str, len)
                )
        {
           chain->value = val;
           return;     /* already there */
        }
    }

    /* nope, must add new entry */
    chain = new_element();
    chain->len = len;
    chain->hash = hash;
    if(hashonaddr) chain->str = str;
    else
     {
        chain->str = (char *)lh_malloc(strlen(str)+1);
        strcpy(chain->str,str);
     }
    chain->next = *chainp;
    chain->value = val;
    *chainp = chain;

    /* do we need to expand the table? */
    if( --(T->slack) < 0 )
        lh_expandtable(T);
    return;
}

/* retrieve string `str' with `len' characters from table `T' */

char *lh_retrieve(char *str, hashtable_t *T)
{
    unsigned hash, address;
    element_t **chainp, *chain;
    unsigned int len;
    int hashonaddr = T->hashonaddr;

    /* locate the bucket for this string */
    if(hashonaddr) {hash = (unsigned int)str; len = sizeof(int);}
    else {len= 1 + strlen(str); hash = HASH(str, len); }
    address = hash & T->maxp_minus_1;
    if( address < T->p )
        address = hash & (2 * T->maxp_minus_1 + 1);

    chainp = &T->directory[DIRINDEX(address)]->elements[SEGINDEX(address)];

    /* is the string already in the hash table? */
    for(chain = *chainp; chain != (element_t*)0; chain = chain->next)
        if(hashonaddr)
        {
           if(chain->hash == hash && chain->str == str)
              return chain->value;
        }
        else if( chain->hash == hash &&
                 chain->len == len &&
                 !memcmp(chain->str, str, len)
               )
            return chain->value;     /* already there */

    /* nope, must return NULL */
    return NULL;
}

void lh_shrinktable(hashtable_t *T)
{
    segment_t *lastseg;
    element_t **chainp;
    unsigned oldlast = T->p + T->maxp_minus_1;

    if( oldlast == 0 )
        return; /* cannot shrink below this */

    /* adjust the state variables */
    if( T->p == 0 ) {
        T->maxp_minus_1 >>= 1;
        T->p = T->maxp_minus_1;
    } else
        --(T->p);
    T->slack -= MAXLOADFCTR;

    /* insert the chain `oldlast' at the end of chain `T->p' */
    chainp = &T->directory[DIRINDEX(T->p)]->elements[SEGINDEX(T->p)];
    while( *chainp != (element_t*)0 )
        chainp = &((*chainp)->next);
    lastseg = T->directory[DIRINDEX(oldlast)];
    *chainp = lastseg->elements[SEGINDEX(oldlast)];
    lastseg->elements[SEGINDEX(oldlast)] = NULL;

    /* if necessary, free the last segment */
    if( SEGINDEX(oldlast) == 0 )
        {
          free((void*)lastseg);
          T->directory[DIRINDEX(oldlast)] = NULL;
        }
}

/* delete string `str' with `len' characters from table `T' */

char *lh_delete(char *str, hashtable_t *T)
{
    unsigned hash, address;
    element_t **prev, *here;
    char *res;
    unsigned int len;
    int hashonaddr = T->hashonaddr;

    /* locate the bucket for this string */
    if(hashonaddr) {hash = (unsigned int)str; len = sizeof(int);}
    else {len= 1 + strlen(str); hash = HASH(str, len); }
    address = hash & T->maxp_minus_1;
    if( address < T->p )
        address = hash & (2 * T->maxp_minus_1 + 1);

    /* find the element to be removed */
    prev = &T->directory[DIRINDEX(address)]->elements[SEGINDEX(address)];
    for(; (here = *prev) != (element_t*)0; prev = &here->next)
    {
        if(hashonaddr)
        {
           if(here->hash == hash && here->str == str) break;
        }
        else if( here->hash == hash &&
                 here->len == len &&
                 !memcmp(here->str, str, len)
                )  break;
    }
    if( here == (element_t*)0 )
        return NULL; /* the string wasn't there! */

    /* remove this element */
    *prev = here->next;
    if(!hashonaddr) free((void*)here->str);
    res = here->value;
    free((void*)here);


    /* do we need to shrink the table? the test is:
     *          keycount / currentsize < minloadfctr
     * i.e.     ((maxp+p)*maxloadfctr-slack) / (maxp+p) < minloadfctr
     * i.e.     (maxp+p)*maxloadfctr-slack < (maxp+p)*minloadfctr
     * i.e.     slack > (maxp+p)*(maxloadfctr-minloadfctr)
     */
    if( ++(T->slack) >
        (int)(T->maxp_minus_1 + 1 + T->p) * (MAXLOADFCTR-MINLOADFCTR)
      )
        lh_shrinktable(T);
    return res;
}

void lh_map(hashtable_t *T, maplh_function f, void *x)
{
    segment_t **directory = T->directory;
    segment_t *segment;
    element_t *bck, *next;
    element_t *de;
    unsigned int i,j;

    for(i=0;i<LH_DIRECTORYSIZE;i++)
    {
      segment = directory[i];
      if(segment!=NULL)
      for(j=0;j<LH_SEGMENTSIZE;j++)
       {
         bck = segment->elements[j];
         if(bck!=NULL)
         for(;bck != NULL; bck=next)
         {
           de = bck;
           next = de->next;
           if(!((f)(de->str,de->value,x))) return;
         }
       }
    }
}

void lh_free(hashtable_t *T)
{
    segment_t **directory = T->directory;
    segment_t *segment;
    element_t *bck, *next;
    element_t *de;
    int i,j;

    for(i=0;i<LH_DIRECTORYSIZE;i++)
    {
      segment = directory[i];
      if(segment!=NULL)
      {
        for(j=0;j<LH_SEGMENTSIZE;j++)
        {
         for(bck=segment->elements[j];bck != NULL; bck=next)
         {
           de = bck;
           next = de->next;
           free(de);
         }
        }
        free(segment);
    }
    }
    //free(directory);
    free(T);
    return;
}


