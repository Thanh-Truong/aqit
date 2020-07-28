/*****************************************************************************
 * AMOS2
 *
 * Author: (c) 2012 Thanh Truong, UDBL
 * $RCSfile: slaslogger.h,v $
 * $Revision: 1.3 $ $Date: 2012/05/24 18:03:40 $
 * $State: Exp $ $Locker:  $
 *
 * Description: Stream (ManchineId, Time, PowCon) into a comma separate file.
 * ===========================================================================
 * $Log: slaslogger.h,v $
 * Revision 1.3  2012/05/24 18:03:40  thatr500
 * Reading generator settings as environement variables
 *
 * Revision 1.2  2012/05/23 07:33:46  thatr500
 * More robust generator
 *
 * Revision 1.1  2012/05/21 07:20:22  thatr500
 * stream (ManchineId, Time, PowCon) into a comma separate file.
 *
 *
 ****************************************************************************/

#ifndef _slaslogger_h_
#define _slaslogger_h_

#include "callin.h"
#include "callout.h"
#include "alisp.h"
#include <time.h>
#include <sys/types.h>
#include <sys/timeb.h>
#if defined(_WIN32) || defined(_WIN64)
#include <windows.h>
#endif
#include "../logger/config.h"
#include "../logger/logger.h"
#include "../lofixP/lofixP.h"
#include "../lofixS/lofixS.h"
#include "slas.h"

struct WriterInfo
{
  size_t nrows_per_block; // number of rows per block
  size_t ncolumns;        // number of columns  
  size_t attribute_size;  // attribute size in bytes
  size_t nrows_per_window; 
  unsigned int rowcount;     // number of rows has been filled in window
  unsigned int nwrite;       // number of writes for a given stream 
  unsigned int indexedpos;

  spos_t offset_startblock;
  spos_t offset_endblock;
  unsigned int blockno;

  FILE*fh;           // file handle 
  struct SLWindow *window;
  LofixP * lxp;
  LofixS * lxs;
};

/*Global array of LofixP indexes maintaining meta-data about log files*/
struct LofixP g_lx[10];

/*Functions*/
oidtype slas_write_indexed_logfilebbf(a_callcontext cxt);


#endif
