#ifndef _SLWIN_STATS_H_
#define _SLWIN_STATS_H_
#include "math.h"
#include "float.h"
#include "stdio.h"
#include "stdlib.h"
#include "slas_portable.h"
#include "amos.h"
#include "storagetypes.h"
#include "storage.h"
#ifdef WIN32
#include <windows.h>
#else 
#include <dlfcn.h>
#endif
unsigned int  SLWINSTATS_TYPE;

/*Amos storagetype Slas window statistic*/
struct SLWinStatsCell {
  objtags tags;
  /* window statistics*/
  int startTime;
  int count;
  double avg;
  double stdev;
  double min;
  double max;
  /* physical info*/
  spos_t   byte_offset; // starting offset 
  long int byte_size;  // total byte offsets
};

/*Make a new instance of SL WinStat storage type*/
oidtype make_winstatsfn(bindtype env, oidtype startTime);

/*Set stat value v*/
oidtype winstats_set_statfn(bindtype env, oidtype wstats, oidtype stat, 
			    oidtype v);
/*Get stat*/
oidtype winstats_get_statfn(bindtype env, oidtype wstats, oidtype stat);

/*Start window*/
oidtype winstats_startfn(bindtype env, oidtype wstats);

/*Stop window*/
oidtype winstats_stopfn(bindtype env, oidtype wstats);

/*Offset window*/
oidtype winstats_offsetfn(bindtype env, oidtype wstats);

/*Byte size window*/
oidtype winstats_byte_sizefn(bindtype env, oidtype wstats);


/*Deallocate given instance of SL WinStat storage type*/
void free_winstatsfn(oidtype winstats);

/*Print out given instance mexi on stream*/
void print_winstatsfn(oidtype winstats, oidtype stream, int princflg);

/*Register a derrived storage type*/
int  register_winstats();

#endif


