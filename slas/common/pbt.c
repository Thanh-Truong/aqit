/*****************************************************************************
 * AMOS2
 *
 * Author: (c) 1999,2011 Tore Risch, UDBL
 * $RCSfile: bt.c,v $
 * $Revision: 1.5 $ $Date: 2012/12/21 11:42:53 $
 * $State: Exp $ $Locker:  $
 *
 * Description: Stand alone memory B-tree implementation
 * ===========================================================================
 * $Log: bt.c,v $
 * Revision 1.5  2012/12/21 11:42:53  torer
 * malloc.h obsolete under Unix
 *
 * Revision 1.4  2012/07/05 18:29:27  sobso953
 * B-tree scan added
 *
 * Revision 1.3  2011/12/30 17:57:51  thatr500
 * Unix convention
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
 * Revision 1.18  2011/12/27 14:45:43  torer
 * Code indentation
 *
 * Revision 1.17  2011/12/13 12:51:33  sobso953
 * conventional free(node) calls in deletion replaced by ADD_To_FREE_LIST(node) macro
 *
 * Revision 1.16  2011/12/02 12:54:35  thatr500
 * assign 0 in BTDelete0
 *
 * Revision 1.15  2011/11/30 17:47:28  sobso953
 * printing functions moved to BT_Tests.c
 *
 * Revision 1.14  2011/11/30 17:07:07  sobso953
 * Tests moved to a separate file
 *
 * Revision 1.13  2011/11/30 16:17:26  thatr500
 * BTDelete returns BTitem instead of BTData
 *
 * Revision 1.12  2011/11/30 12:33:04  thatr500
 * Modified the deletion signature
 *
 * Revision 1.11  2011/11/30 11:08:15  sobso953
 * BTree defenitions were moved into BT.h
 *
 * Revision 1.10  2011/11/30 10:23:49  sobso953
 * .deleted flag in the nodes removed
 *
 * Revision 1.9  2011/11/30 10:15:57  thatr500
 * - Removed ex_mappingfn,
 * - Added calledFromDLL flag
 *
 * Revision 1.8  2011/11/30 09:59:09  sobso953
 * .deleted is back!
 *
 * Revision 1.6  2011/11/30 09:04:58  sobso953
 * BTree deletion added
 *
 * Revision 1.5  2011/04/27 15:56:02  thatr500
 * increase size of BTnode ( changing HALF_SIZE) to 750
 *
 * Revision 1.4  2011/04/23 12:06:54  thatr500
 * added BTComparer to BTget, BTdelete to generalize the implementation.
 *
 * Revision 1.3  2011/04/21 10:10:10  torer
 * Fast delete by using free list of BT nodes
 *
 * Revision 1.2  2011/04/20 20:47:49  thatr500
 * added one extra mapperfn to BTmap0
 *
 * Revision 1.1  2011/04/15 08:20:41  torer
 * Stand-alone main memory B-tree
 *
 ****************************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include "pbt.h"

int nodecnt = 0;
BTnode *freeBTnodes = NULL;

int compareBTdata(BTdata a,BTdata b)
{
  if(a<b) return -1;
  if(a>b) return 1;
  return 0;
}

BThead *newBThead(void)
{
  BThead *res = malloc(sizeof(*res));

  res->root = NULL;
  res->elements = 0;
  res->items=0;
  return res;
}

BTnode *newBTnode (void)
{
  register BTnode *res;
  int i;

  if(freeBTnodes == NULL) res = malloc(sizeof(*res));
  else
    {
      res = freeBTnodes;
      freeBTnodes = res->p0;
    }
  res->m = 0;
  res->p0 = NULL;
  for(i=0; i<2*HALF_SIZE; i++)
    {
      res->e[i].p = NULL;

    }
  nodecnt++;
  return res;
}

int freeBTnode(BTnode *node)
{
  unsigned int i, cnt=0;

  if(node->p0 != NULL) cnt = cnt + freeBTnode(node->p0);
  for(i=0;i<node->m;i++)
    {
      BTitem bi = node->e[i];

      if(bi.p!=NULL) 
	cnt = cnt + freeBTnode(bi.p);
      bi.p = NULL;
    }
  
  ADD_To_FREE_LIST(node)

  return cnt+1;
}

//releases memory allocated to all nodes that were deleted,
//returns amount of memory (in byte) that was released
int releaseBTMem(){
	
	BTnode *node_to_free;
	int cnt=0;

	while(node_to_free==freeBTnodes)
	{
		;
		freeBTnodes=freeBTnodes->p0;
		free(node_to_free);
		cnt++;
	}

	return (cnt*sizeof(BTnode));
}

int freeBThead(BThead *bt)
{
  int cnt;

  if(bt->root == NULL) return 0;
  cnt = freeBTnode(bt->root);
  free(bt);
  return cnt;  
}

BTitem *BTinsert1(BThead *bh, BTdata k, BTnode *bn, int *h, 
                  BTitem *ui, BTcomparer fn)
     /* Search key k in B-tree with root bn; if found, return BTitem.
	Otherwise insert new item with key k. If an item is passed up,
	assign it to ui. h is flag indicating that tree has become higher */
{
  register unsigned int i, L, R;
  BTnode *newbn;
  BTitem u, *res;

  if(bn == NULL)
    {
      *h = TRUE; /* Not in tree */
      ui->data.key = k;
      /* The caller will always update the value */
      bh->elements++;
      ui->p = NULL;
      (bh->items)++;
      return NULL;
    }
  else
    {
      register BTdata d;

      L = 1;
      R = bn->m + 1;  /* Binary search */
      while(L<R)
	{
          i = (L+R)/2;
          d = bn->e[i-1].data.key;
          if(COMPARE_BITEMS(d,k,fn) <= 0) L = i + 1;
          else R = i;
	}
      R--;
      d = bn->e[R-1].data.key;
      if(R>0 && COMPARE_BITEMS(d,k,fn)==0)
	{  
          /* Return old KVP */
          res = &(bn->e[R-1]);
          /* The caller sets the value */
          *h = FALSE; /* Height did not increase */
          return res;
	}
      else
	{
          /* BTitem not in this node */
          if(R == 0) res = BTinsert1(bh, k, bn->p0, h, &u, fn);
          else res = BTinsert1(bh, k, bn->e[R-1].p, h, &u, fn);
          if(*h) /* u is new item to insert */
	    {
	      /* Insert u to the right of e[R-1] */
	      if(bn->m < 2*HALF_SIZE)
		{
		  *h = FALSE; /* Move new item to bn->e[R] */
		  bn->m++;
		  memmove(&(bn->e[R+1]),&(bn->e[R]),
                          sizeof(BTitem)*(bn->m-R-1));
		  bn->e[R] = u; /* Assign BTitem */
		  if(res == NULL) res = &(bn->e[R]);
		}
	      else
		{
		  newbn = newBTnode();  /* overflow */
		  /* Split bn into bn, newbn and assign the middle 
                     BTitem to ui */
		  if(R <= HALF_SIZE)
		    {
		      if(R == HALF_SIZE) *ui = u;  /* Assign BTitem */
		      else
			{
			  *ui = bn->e[HALF_SIZE-1];
			  memmove(&(bn->e[R+1]),
				  &(bn->e[R]),sizeof(BTitem)*(HALF_SIZE-R-1));
			  bn->e[R] = u; /* Assign BTitem */
			  if(res == NULL)res = &(bn->e[R]);
			}
		      memcpy(newbn->e,
			     &(bn->e[HALF_SIZE]),
			     sizeof(BTitem)*HALF_SIZE);
		    }
		  else
		    {
		      /* Insert in right half */
		      R = R - HALF_SIZE;
		      *ui = bn->e[HALF_SIZE];
		      memcpy(newbn->e, 
			     &(bn->e[1+HALF_SIZE]),
			     sizeof(BTitem)*(R-1));
		      newbn->e[R-1] = u; /* Assign BTitem */
		      if(res == NULL) res = &(newbn->e[R-1]);
		      memcpy(&(newbn->e[R]),
			     &(bn->e[R+HALF_SIZE]),
			     sizeof(BTitem)*(HALF_SIZE-R));
		    }
		  bn->m = HALF_SIZE;
		  newbn->m = HALF_SIZE;
		  newbn->p0 = ui->p;
		  ui->p = newbn;
		}
	    }
          return res;
	}
    }
}

BTitem *BTinsert(BThead *bh, BTdata  k, BTcomparer fn)
{
  BTitem ui, *res;
  int became_higher;
  BTnode *root, *q;

  root = bh->root;
  res = BTinsert1(bh, k, root, &became_higher, &ui, fn);
  
  if(became_higher) /* Tree became higher */
    {
      q = root;
      root = newBTnode();
      root->m = 1;
      root->p0 = q;
      root->e[0] = ui;
      bh->root = root;
      if(res == NULL) return &(root->e[0]);
    }
  return res;
}

void BTinsert_value(BThead *bh, BTdata  k, BTdata v, BTcomparer fn)
{
  BTitem *bti;

  bti = BTinsert(bh, k, fn);
  bti->data.value = v;
}

int BTmap0(BTnode *bt, BTdata lower, BTdata upper, 
	   BTmapper fn, BTcomparer cfn, void *xa)
{
  unsigned int  i;

  if(bt == NULL) return TRUE;
  else
    {
      register int leftdone=FALSE, cmp;
      BTdata dk;

      i=1;
      /* Code for binary searching for lower */
      { 
	unsigned int L, R;

	cmp = COMPARE_BITEMS(lower,bt->e[0].data.key,cfn);
	if(cmp>0)
	  {
	    L = 1;
	    R = bt->m + 1;
	    while(L<R)
	      {
		i = (L+R)/2;
		cmp = COMPARE_BITEMS(lower,bt->e[i-1].data.key, cfn);
		if(cmp == 0) break;
		if(cmp > 0) L = i + 1;
		else R = i;
	      }
	  }
      }
      for(i=i-1;i<bt->m;i++) /* Scan forward until passed upper */
	{
	  dk = bt->e[i].data.key;
	  cmp = COMPARE_BITEMS(lower,dk,cfn);
	  if(cmp<=0)
	    {
	      if(!leftdone)
		{
		  if(cmp==0);
		  else if(i==0)
		    {
		      if(!BTmap0(bt->p0,lower,upper,fn, cfn,xa))
			return FALSE;
		    }
		  else
		    {
		      if(!BTmap0(bt->e[i-1].p,lower,upper,fn, cfn,xa))
			return FALSE;
		    }
		  leftdone = TRUE;
		}
	      dk = bt->e[i].data.key;
	      if(COMPARE_BITEMS(dk,upper,cfn)>0)
		{
		  if(!BTmap0(bt->e[i].p,lower,upper,fn, cfn,xa))
		    return FALSE;
		  break;
		}
	      else
		{
		  /*printf("Key:%d\n",bt->e[i].key); */
		  if(fn != NULL) {
		    if(!((*fn)(&(bt->e[i]),xa))) return FALSE;
		  } 
		  
		  if(!BTmap0(bt->e[i].p,lower,upper,fn, cfn,xa))
		    return FALSE;
		}
	    }
	  else
	    if(i==bt->m-1) return BTmap0(bt->e[i].p,lower,upper,fn, cfn,xa);
	}
    }
  return TRUE;
}

int BTgetMapper(BTitem *bi, void *xa)
{
  *((BTitem **)xa) = bi;
  return FALSE;
}

BTitem *BTget(BThead *bh, BTdata key, BTcomparer cmpfn)
{
  BTitem *res=NULL;
 
  BTmap0(bh->root,key,key,BTgetMapper, cmpfn,(void *)&res);
  if(res==NULL) return NULL;
  return res;
}

//handels the aftermath of deletion in case a node underflows
void BTunderflow(BTnode* c, BTnode* a, unsigned int s, int* h,BThead* bh)
{
  /*
    a = underflowing node
    c = ancestor node
    s = index of deleted entry in c
    h = underflow flag, set to 1 if underflow propagates upward
    bh= root node of b-tree
  */
  BTnode* b=NULL;
  int i=0,k=0;
  unsigned int N=HALF_SIZE;

  /*h & (a.m = N-1) & (c.e[s-1].p = a) */

  if (s<c->m)/*b := page to the right of a*/
    {
      b=c->e[s].p; 
      k= (b->m-N+1)/2;/*k = nof items available on page b*/
      a->e[N-1]=c->e[s]; a->e[N-1].p=b->p0;//move one element from c to a
      if(k>0)/*balance by moving k-1 items from b to a, one from b to c*/
	{
	  memcpy(&a->e[N],&b->e[0],(k-1)*sizeof(BTitem));
	  //moving k-1 items from b to a
	  c->e[s]=b->e[k-1]; b->p0= c->e[s].p;//one from b to c
	  c->e[s].p= b; b->m=b->m-k;
	  memmove(&b->e[0],&b->e[k],b->m*sizeof(BTitem));
	  //Left shift elements of b
	  a->m=N-1+k; *h = 0;
	}
      else /*merge pages a and b, discard b*/
	{
	  memcpy(&a->e[N],&b->e[0],N*sizeof(BTitem));
	  //move all items (N) in b to a 
	  c->m--;
	  memmove(&c->e[s],&c->e[s+1],(c->m-s)*sizeof(BTitem));
	  //Left shift elements of c
	  a->m = 2*N; *h = (c->m < N);
					
	  ADD_To_FREE_LIST(b)//replaced [free(b);]

	    if (c->m==0)//only in case root node has become empty
	      {
		bh->root=a;
		ADD_To_FREE_LIST(c)//replaced [free(c);]
		  }
	}
    }
  else/*b := page to the left of a*/
    {
      s--;//s has to point to previous element in the node c
      if(s==0) b=c->p0;else b = c->e[s-1].p;
      k=(b->m-N+1)/2; /*k = nof items available on page b*/
      if (k>0)
	{
	  //Right shift elements in a to make space for migrating elements 
          //coming from b
	  memmove(&a->e[k],&a->e[0],(N-1)*sizeof(BTitem));
	  a->e[k-1]=c->e[s];a->e[k-1].p=a->p0;
	  /*move k-1 items from b to a, one to c*/
	  b->m=b->m-k;
	  memcpy(&a->e[0],&b->e[b->m+1],(k-1)*sizeof(BTitem));
	  c->e[s] = b->e[b->m]; a->p0=c->e[s].p;
	  c->e[s].p= a; a->m=N-1+k; *h=0;
	}
      else /*merge pages a and b, discard a*/
	{
	  c->e[s].p=a->p0; b->e[N]=c->e[s];
	  memcpy(&b->e[N+1],&a->e[0],(N-1)*sizeof(BTitem));
	  //move N-1 elements from a to b
	  b->m=2*N; c->m--; *h = (c->m < N);
	  if (c->m==0)//only in case root node has become empty
	    {
	      bh->root=b;
	      ADD_To_FREE_LIST(c)//replaced [free(c);]
		}
			
	  ADD_To_FREE_LIST(a)//replaced [free(a);]
	    }
    }
  return;
}

//removes an element from internal nodes
//The replacement is found by following the right most pointers of 
//the left child.
void BTdel(BTnode* p,BTnode* a, int* R,int* h,BThead *bh)
{
  /*
    p= where the replacement exists (eventually)
    a= internal node that contains the element to be deleted/replaced
    R= The index of node to be deleted/replaced in a
    h = underflow flag, set to 1 if underflow happens
    bh= root node of b-tree
  */
  int k;
  unsigned int N=HALF_SIZE;
  BTnode* q;
  //points to next node to be investigated as the one that 
  //contains replacement

  k=p->m-1;
  //k points to the right most child, i.e looking for the biggest key in 
  //left sub-tree
  q=p->e[k].p;
  if (q!=NULL)
    {
      BTdel(q,a,R,h,bh);
      if (*h)
	BTunderflow(p,q,p->m,h,bh);
      //Debug: Changed from p->m to p->m-1??Wrong!! changed back
    }
  else//p is a leaf node, no need to follow up more.
    {
      //Move the biggest key item in P to the intermediate node
      p->e[k].p=a->e[*R].p;
      a->e[*R]=p->e[k];
      p->m--;
      *h= (p->m < N);//signals if p underflows after borrowing an element
    }
  return;
}

//removs key x from sub-tree a in btree bh
//return the value that used to be associated with key x, 
//if x does not exist, return 0
//If x was successfully deleted, item will carry deleted <key,val> pair
int BTdelete0(BTdata x, BTnode* a,int* h,BThead *bh, BTcomparer fn, BTitem* item)
{
  /*
    x= the key to be removed
    a= sub tree in which key x is supposed to be
    h = underflow flag, set to 1 if underflow happens
    bh= root node of b-tree
  */
  int i,L,R,delflag=0;
  BTnode* q;//child node to look for x, in case x is not found in a
  unsigned int N=HALF_SIZE;

  if(a!=NULL)
    {
      L=0;R=a->m;
      while(L<R)/*binary search in node a*/
	{
	  i=(L+R)/2;
	  if(COMPARE_BITEMS(x,a->e[i].data.key,fn)!=1)
	    R=i;
	  else
	    L=i+1;
	}
      if(R==0)
	q=a->p0;
      else
	q=a->e[R-1].p;
      if((R < (int) a->m) && (COMPARE_BITEMS(a->e[R].data.key,x,fn)==0))
        //found it!
	{
	  item->data.key =a->e[R].data.key;
	  item->data.value =a->e[R].data.value;
	  delflag=1;
	  if(q==NULL)/*a is leaf page*/
	    {
	      a->m--;
	      *h=(a->m<N);
	      memmove(&a->e[R],&a->e[R+1],(a->m-R)*sizeof(BTitem));
	      //Left shift items in a 
	    }
	  else/*a is an internal node*/
	    {
	      BTdel(q,a,&R,h,bh);
	      if(*h)
		BTunderflow(a, q, R, h,bh);
	    }
	}
      else/*x not found in a, continue by searching q*/
	{
	  delflag=BTdelete0(x, q, h,bh,compareBTdata,item);
	  if(*h)
	    BTunderflow(a, q, R, h,bh);
	}
    }
  return delflag;
}

//deletes key x from Btree bh
//if key is found returns the value associated with key x, 
//otherwise returns 0 signalling that key x did not exist.
int BTdelete(BThead *bh,BTdata key, BTcomparer cmpfn,BTitem* item)
{
  int h=0;
  int delflag=0;
  
  if (item==NULL)
  {
	  printf("Null value passed for item\n");
	  return 0;
  }
  if (delflag==BTdelete0(key,bh->root,&h,bh,cmpfn,item))
	  bh->elements--;
  return delflag;
}

// searches the B-tree node to by node for key k
// such that k is the smallest key that holds k<=lower,
// returns a pointer to the BTitem bti containing the found key
// also returns a cursor for consecutive in order retrievals
void BT_cursor_init(BTnode *node,BTdata lower,BTcomparer cmpfn,BTcursor* Pcursor){
	
	// the offset is at the lowest possible grain, from 0 to 2*m
	// this allows distinction between pointers and keys
	// one might be able to elliminate this in future...

	unsigned int L,R;
	int i,delflag=0;
	BTnode* q;//child node to look for lower, in case it is not found in node
	

	if(!node)
		return;
	//binary search to find the lower
	L=0;R=node->m;
	while(L<R)/*binary search in node a*/
	{
		i=(L+R)/2;
		if(COMPARE_BITEMS(lower,node->e[i].data.key,cmpfn)!=1)
		R=i;
		else
		L=i+1;
	}
	//case 1: the key k=lower is found in the current node
	if((R < (int) node->m) && (COMPARE_BITEMS(node->e[R].data.key,lower,cmpfn)==0))
	{
		ADD_TO_TRAIL(Pcursor, node, R*2+1);
		return;
	}
	else//lower not found
	{
		//q points to the child-node in which the search proceeds
		if(R==0)
			q=node->p0;
		else
			q=node->e[R-1].p;

		if(q){//the search has to continue
			ADD_TO_TRAIL(Pcursor, node, R*2+1);//R*2 identifies the pointer to q
			BT_cursor_init(q,lower,cmpfn,Pcursor);
			//if nothing is found later in the recursion,
			//AND, no key k exists in this node, then
			//undo the ADD_TO_TRAIL(Pcursor, node, R);
			if (((*Pcursor)->p==node)&& R>=node->m)
				Drop_HEAD_TRAIL(Pcursor);
		}
		else
		{//no more search possible
			if(R<node->m)//key k is found in this node -> mark it
					{
						ADD_TO_TRAIL(Pcursor, node, R*2+1);//R*2+1 identifies a key in this node
						return;
					}
			else//deadend, no such key k in this node, just return.
				return;
		}
	}
}

//moves forward the B-tree cursor pointed to by Pcursor
void BT_cursor_next(BTcursor* Pcursor){

	BTcursor_cell* current_element;
	BTnode* current_node;
	BTnode* q;//the right child pointer
	unsigned int node_offset;//where in the node the offset maps to
	unsigned int offset;//the original grain offset
	int drop_flag=1;

	current_element=*Pcursor;
	current_node=current_element->p;
	offset=current_element->offset;
	node_offset=offset/2;
	
	q=current_node->e[node_offset].p;

	if(//it is still posible to consume more from the current node
		node_offset<current_node->m-1//keys except the last one in the node
		||
		(q && node_offset==current_node->m-1)// the last key in the node has right sub-trees
		)
	{
		
		if(!q && node_offset<current_node->m-1)
		//the simplest case: next key is in the same node
		{
			current_element->offset+=2;
			return;
		}
		else
		{
			current_element->offset+=2;
			//not simple, get to the left most in q sub-tree
			while(q)//while there are deeper levels
			{
				//current_element=*Pcursor;
				//current_element->offset+=2;
				ADD_TO_TRAIL(Pcursor, q, 1);
				q=q->p0;
			}
			return;
		}
	}
	else
	//the current node is completely exploited
	{
		//drop the current element in the trail.
		Drop_HEAD_TRAIL(Pcursor);
		
		current_element=*Pcursor;
		current_node=current_element->p;
		offset=current_element->offset;
		q=current_node->e[offset/2].p;

		//backtrack by droping the head of the trail.
		// drop heads as long as the offset points to the last element.
		while((offset>=current_node->m*2))
		{
			Drop_HEAD_TRAIL(Pcursor);
			if (!(*Pcursor))//when the trail becomes empty
				break;//i.e last key in the whole tree is visited
			current_element=*Pcursor;
			current_node=current_element->p;
			offset=current_element->offset;
			q=current_node->e[offset/2].p;
		}
	}

}
