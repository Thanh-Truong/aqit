/*****************************************************************************
 * AMOS2
 *
 * Author: (c) 2011 Sobhan.B, UDBL
 * $RCSfile: bt.h,v $
 * $State: Exp $ $Locker:  $
 *
 * Description: IDXLF header file
 * ===========================================================================
 * $Log: lofixS.h,v $
 *
 ****************************************************************************/

#ifndef _LOFIX_S_H_
#define _LOFIX_S_H_
#include "stdio.h"
#include "limits.h"
#include "../../common/slas_portable.h"
#include "../../../extenders/BTREE/bt.h"
#include "../../../C/environ.h"
#define LRKEY_MIN INT_MIN  
#define LRKEY_MAX INT_MAX

//typedef struct LRValue LRValue;
//typedef struct LofixS LofixS;
typedef double LRKey;

typedef spos_t LRValue;

typedef struct LofixS {
struct BThead* bt;
char logfilename[50];
} LofixS;


typedef int (* LofixSMapper) (void *k, void *v,  void *xa);
typedef int (*LofixSComparer)(LRKey, LRKey);


/*----------------------------------------------------------------------------------------------
Interface
------------------------------------------------------------------------------------------------*/
EXPORT LofixS* lofixS_create(void);
EXPORT int lofixS_insert(LofixS * lx, LRKey key, LRValue lrv, LofixSComparer fn);
EXPORT void lofixS_map(LofixS *lx, LRKey lower, LRKey upper,LofixSMapper fn, LofixSComparer cfn, void *xa);
EXPORT LRValue* lofixS_get(LofixS * lx, LRKey key, LofixSComparer cmpfn);
EXPORT void lofixS_release(LofixS *lx);
#endif
