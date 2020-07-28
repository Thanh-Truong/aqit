/*****************************************************************************
 * AMOS2
 *
 * Author: (c) 2011 Sobhan.B, UDBL
 * $RCSfile: bt.h,v $
 * $State: Exp $ $Locker:  $
 *
 * Description: Btree header file
 * ===========================================================================
 * $Log: bt.h,v $
 * Revision 1.3  2012/07/05 18:29:27  sobso953
 * B-tree scan added
 *
 * Revision 1.2  2011/12/30 15:23:50  sobso953
 * 1-BTree deletion returns a pointer 2-BThead.elements updated after deletion
 *
 * Revision 1.1  2011/12/30 11:03:14  torer
 * BTREE extender added
 *
 * Revision 1.1  2011/12/29 17:36:48  torer
 * Stored all BTREE index code in separate directory
 *
 * Revision 1.6  2011/12/13 12:49:31  sobso953
 * ADD_To_FREE_LIST(X) macro added
 *
 * Revision 1.5  2011/12/13 09:50:38  thatr500
 * compare undefined value
 *
 * Revision 1.4  2011/11/30 17:49:13  sobso953
 * signature for compareBTdata added
 *
 * Revision 1.3  2011/11/30 16:17:26  thatr500
 * BTDelete returns BTitem instead of BTData
 *
 * Revision 1.2  2011/11/30 12:33:04  thatr500
 * Modified the deletion signature
 *
 * Revision 1.1  2011/11/30 11:08:15  sobso953
 * BTree defenitions were moved into BT.h
 *
 *
 ****************************************************************************/

#ifndef _BT_H_
#define _BT_H_
#define HALF_SIZE (750/sizeof(BTitem)-1)
#define DB_SIZE 10000000
#include "limits.h"
#define TRUE 1
#define FALSE 0

typedef void *BTdata;
typedef struct BTitem BTitem;
typedef struct BTnode BTnode;
typedef struct BThead BThead;

struct BTitem
{
  BTnode *p;    /* Points to child BTree node */
  struct {BTdata key; BTdata value;} data;
};

struct BTnode  /* Template for btree node */
{
  unsigned int m;             /* No of BTitems in node */
  BTnode *p0;                 /* Pointer to child */
  BTitem e[2*HALF_SIZE];      /* Items in node */
};

struct BThead
{     
  BTnode *root;               /* Pointer to root btree node */
  int elements;               /* Number of non-deleted items in Btree */
  int items;                  /* Total number of items in Btree */
};

typedef int (*BTmapper) (BTitem *,void *);
typedef int (*BTcomparer)(BTdata, BTdata);

/* Macros for fast dispatch between integer comparison and user provided
  comparison function: */
#define COMPARE_BITEMS(x,y,fn)(fn?(*fn)(x,y):COMPARE(x,y))
#define COMPARE(x,y) ((x)<(y)?-1:((x)>(y)?1:0))

//macro to add a BT node to the free list
#define ADD_To_FREE_LIST(X) {X->p0 = freeBTnodes;freeBTnodes = X;nodecnt--;}

////////////////////////////////////////////////////////////
///////////////////B-tree cursor////////////////////////////
////////////////////////////////////////////////////////////

typedef struct BTcursor_cell BTcursor_cell;//cells in the trail
typedef BTcursor_cell* BTcursor;//the cursor structure

//this structure holds a detailed pointer to a B-tree node
struct BTcursor_cell
{
	BTnode *p;//the node pointer
	unsigned int offset;//the offse
	BTcursor_cell* next;
};

// macro to add node with specified offset to the
// trail cursor to the beginning of the trail
// INPUT TYPES: BTcursor* cursor, BTnode* node, int offset
#define ADD_TO_TRAIL(Pcursor, node, in_offset)		\
{													\
	BTcursor_cell* new_element;						\
	new_element=malloc(sizeof(BTcursor_cell));		\
	new_element->p=node;							\
	new_element->offset=in_offset;					\
	new_element->next=*Pcursor;						\
	*Pcursor=new_element;							\
}

// Drops the head of trail, used to backtrack if
// ADD_TO_TRAIL turns out to be unnecessary
#define Drop_HEAD_TRAIL(Pcursor)		\
{										\
	BTcursor_cell* __current_trail__;	\
	__current_trail__=*Pcursor;			\
	*Pcursor=(*Pcursor)->next;			\
	free(__current_trail__);			\
}

//releases all cursor objects created for Pcursor
#define FREE_CURSOR(Pcursor)			\
{										\
	BTcursor_cell* __current_cursor__;	\
	while (Pcursor)						\
	{									\
		__current_cursor__=Pcursor;		\
		Pcursor=Pcursor->next;			\
		free(__current_cursor__);		\
	}									\
	Pcursor=NULL;						\
}

//returns the current element pointed to by cursor
//if offset is pointing to the end of a node, there
//the result set is empty
#define CURSOR_CURRENT(cursor)					\
	(											\
	(cursor&&(cursor->offset<(cursor->p->m)*2))?\
	&(cursor->p->e[(cursor->offset)/2])			\
	:											\
	NULL										\
	);
////////////////////////////////////////////////////////////
/////////////////B-tree cursor end//////////////////////////
////////////////////////////////////////////////////////////

BThead *newBThead(void);
int freeBThead(BThead *bt);
int releaseBTMem();
BTitem *BTinsert(BThead *bh, BTdata  k, BTcomparer fn);
int BTmap0(BTnode *bt, BTdata lower, BTdata upper,BTmapper fn, BTcomparer cfn, void *xa);
BTitem *BTget(BThead *bh, BTdata key, BTcomparer cmpfn);
int BTdelete(BThead *bh,BTdata key, BTcomparer cmpfn,BTitem* item);
void BTinsert_value(BThead *bh, BTdata  k, BTdata v, BTcomparer fn);
void BT_cursor_init(BTnode *node,BTdata lower,BTcomparer cmpfn,BTcursor* Pcursor);
void BT_cursor_next(BTcursor* Pcursor);

int compareBTdata(BTdata a,BTdata b);
#endif
