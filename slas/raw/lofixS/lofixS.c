/*****************************************************************************
* AMOS2
*
* Author: (c) 1999,2011 Tore Risch, UDBL
* $RCSfile: bt.c,v $
* $Revision: 1.5 $ $Date: 2012/12/21 11:42:53 $
* $State: Exp $ $Locker:  $
*
* Description: Stand alone IDXLF (IndexLogFile)
* ===========================================================================
* $Log: lofixS.c,v $
*
****************************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include "lofixS.h"
#define TRUE 1
#define FALSE 0
/*---------------------------------------------------------------------------*/
LofixS* lofixS_create(void){
  BThead *bh;
  LofixS *lx;
  lx = malloc(sizeof(*lx)); // Allocate new LofixS
  bh = newBThead();         // Allocate a new Btree header 
  lx->bt = bh;              // Point LofixS to bh    
  return lx;
}
/*---------------------------------------------------------------------------*/
int lofixS_insert(LofixS * lx, LRKey key, LRValue lrv, LofixSComparer fn){
  if (lx != NULL && lx->bt != NULL) {
    //printf("lofixS_insert record (key %.3f)  \n",  key);
    BTinsert_value(lx->bt,(BTdata)(&key),(BTdata) (&lrv), fn);
    return TRUE;
  }	
  return FALSE;
}

/*---------------------------------------------------------------------------*/
LRValue* lofixS_get(LofixS * lx, LRKey key, LofixSComparer cmpfn){
 
  return NULL;
}
/*---------------------------------------------------------------------------*/
struct applyMapData
{
	LofixSMapper mapfn;
	void* xa;
};
int releaseRecordInfo(LRKey k, LRValue* lbv,  void *xa){
	free(lbv);
	printf("Free Record Info %d \n", (int)k);
	return TRUE;
}

void lofixS_release(LofixS *lx) {
  if (lx != NULL) {
    // release memory 
    lofixS_map(lx,(LRKey) 1, (LRKey) LRKEY_MAX, (LofixSMapper) releaseRecordInfo, NULL, NULL);
    freeBThead(lx->bt);
  }
}
int apply_single_LRKeyValue(BTitem *bi, void *xa)
{
	struct applyMapData *btxa = (struct applyMapData *)xa;  
	if (btxa != NULL && btxa->mapfn != NULL) {
		return btxa->mapfn((void *) bi->data.key,(LRValue*) bi->data.value, btxa->xa);	
	} 
	return TRUE;
}

/*---------------------------------------------------------------------------*/
void lofixS_map(LofixS *lx, LRKey lower, LRKey upper,LofixSMapper mapfn, LofixSComparer cmpfn, void *xa){
  struct applyMapData btxa;
  if (lx != NULL) {
    BThead *bt = (BThead *)lx->bt;
    
    btxa.mapfn = mapfn;
    btxa.xa = xa;
    BTmap0(bt->root, (BTdata)(&lower), (BTdata)(&upper), 
	   (BTmapper)apply_single_LRKeyValue, (BTcomparer)cmpfn, (void *)&btxa);
  }  
}

