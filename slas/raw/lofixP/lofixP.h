/*****************************************************************************
 * AMOS2
 *
 * Author: (c) 2011 Sobhan.B, UDBL
 * $RCSfile: bt.h,v $
 * $State: Exp $ $Locker:  $
 *
 * Description: LOFIX-P header file
 * ===========================================================================
 * $Log: lofixP.h,v $
 *
 ****************************************************************************/

#ifndef _LOFIX_P_H_
#define _LOFIX_P_H_
#include "stdio.h"
#include "limits.h"
#include "../../common/slas_portable.h"
#include "../../../extenders/BTREE/bt.h"
#include "../../../C/environ.h"
#define LBKEY_MIN INT_MIN  
#define LBKEY_MAX INT_MAX

//typedef struct LBValue LBValue;
//typedef struct LofixP LofixP;
typedef void *LBKey;

struct LBValue{
	spos_t offset_start;  // offset position of the first row in the block
	spos_t offset_end ;   // offset position where the block ends  
	long   count ;        // how many rows in the block
	char indexedPos;      // position of indexed attribute in a row
	double maxIndexedAtt; // max(Att) column
	double minIndexedAtt; // max(Att) column
};


typedef struct LofixP {
	struct BThead* bt;
	struct LofixS* lxs;
	char logfilename[50];
} LofixP;


typedef int (* LofixPMapper) (void *k, void *v,  void *xa);
typedef int (*LofixPComparer)(LBKey, LBKey);


/*----------------------------------------------------------------------------------------------
Interface
------------------------------------------------------------------------------------------------*/
EXPORT LofixP* lofixP_create(void);
EXPORT int lofixP_insert(LofixP * lx, LBKey key, struct LBValue *lbv, LofixPComparer fn);
EXPORT void lofixP_map(LofixP *lx, LBKey lower, LBKey upper,LofixPMapper fn, LofixPComparer cfn, void *xa);
EXPORT struct LBValue* lofixP_get(LofixP * lx, LBKey key, LofixPComparer cmpfn);
EXPORT void lofixP_release(LofixP *lx);

EXPORT int lofixP_update(LofixP * lx, LBKey key, struct LBValue *lbv, LofixPComparer fn, int blockstart, int blockend);

#endif
