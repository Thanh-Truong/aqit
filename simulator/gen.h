/*****************************************************************************
 * AMOS2
 *
 * Author: (c) 2012 Thanh Truong, UDBL
 * $RCSfile: gen.h,v $
 * $Revision: 1.3 $ $Date: 2012/05/24 18:03:40 $
 * $State: Exp $ $Locker:  $
 *
 * Description: Stream (ManchineId, Time, PowCon) into a comma separate file.
 * ===========================================================================
 * $Log: gen.h,v $
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

#ifndef _gen_h_
#define _gen_h_

#include "..\..\C\callin.h"
#include "..\..\C\callout.h"
#include <time.h>
#include <sys/types.h>
#include <sys/timeb.h>
#include <windows.h>


/*Variables*/
int machine;
struct timeval baseTime;
FILE* f;
int MAX_MACHINE;

/*Functions*/
void init_time(struct timeval* res, int year, int month, int day, int hour, int minute, int second);
void read_MachineConfig(); 
oidtype streamtofilebbf(a_callcontext cxt);

#endif
