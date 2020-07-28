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
* $Log: lofixP.c,v $
*
****************************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include "lofixP.h"

/*---------------------------------------------------------------------------*/
LofixP* lofixP_create(void){
	BThead *bh;
	LofixP *lx;
	lx = malloc(sizeof(*lx)); // Allocate new LofixP 
	bh = newBThead();         // Allocate a new Btree header 
	lx->bt = bh;              // Point LofixP to bh    
	return lx;
}
/*---------------------------------------------------------------------------*/
int lofixP_insert(LofixP * lx, LBKey key, struct LBValue *lbv, LofixPComparer fn ){
	if (lx != NULL && lx->bt != NULL) {
		printf("lofixP_insert block (key %d, offset_start %llu offset_end %llu \n", 
			(unsigned int)key, lbv->offset_start, lbv->offset_end);
		BTinsert_value(lx->bt,(BTdata)key,(BTdata) lbv, fn);
		return TRUE;
	}	
	return FALSE;
}
/*---------------------------------------------------------------------------*/
struct LBValue* lofixP_get(LofixP * lx, LBKey key, LofixPComparer cmpfn){
	if (lx != NULL && lx->bt != NULL) {
		BTitem *res=NULL; 
		res = BTget(lx->bt,key, cmpfn);
		return (res == NULL)?NULL:(res->data.value);	
	}
	return NULL;
}
/*---------------------------------------------------------------------------*/
struct applyMapData
{
	LofixPMapper mapfn;
	void* xa;
};

int apply_single_LBKeyValue(BTitem *bi, void *xa)
{
	struct applyMapData *btxa = (struct applyMapData *)xa;  
	if (btxa != NULL && btxa->mapfn != NULL) {
		return btxa->mapfn((void *) bi->data.key,(struct LBValue*) bi->data.value, btxa->xa);	
	} 
	return TRUE;
}

void lofixP_map(LofixP *lx, LBKey lower, LBKey upper,LofixPMapper mapfn, LofixPComparer cmpfn, void *xa){
	struct applyMapData btxa;
	if (lx != NULL) {
		BThead *bt = (BThead *)lx->bt;
		
		btxa.mapfn = mapfn;
		btxa.xa = xa;
		BTmap0(bt->root, (BTdata)lower, (BTdata)upper, 
			(BTmapper)apply_single_LBKeyValue, (BTcomparer)cmpfn, (void *)&btxa);
	}  
}
/*---------------------------------------------------------------------------*/
int releaseBlockInfo(LBKey k, struct LBValue* lbv,  void *xa){
	free(lbv);
	printf("Free Block Info %d \n", (int)k);
	return TRUE;
}

void lofixP_release(LofixP*lx){
	if (lx != NULL) {
		// release memory 
		lofixP_map(lx,(LBKey) 1, (LBKey) LBKEY_MAX, (LofixPMapper) releaseBlockInfo, NULL, NULL);
		freeBThead(lx->bt);
	}

}
/*---------------------------------------------------------------------------*/
int lofixP_update(LofixP * lx, LBKey key, struct LBValue *lbv, LofixPComparer fn, int blockstart, int blockend){
	if (lx->bt != NULL) {
		if (blockstart== TRUE) {
			
		}
		if (blockend == TRUE) {

		}
		return TRUE;
	}
	return FALSE;
}
