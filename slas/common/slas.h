#ifndef _SLAS_H_
#define _SLAS_H_


#undef NUM_ROWS_IN_BLOCK
#define  NUM_ROWS_IN_BLOCK  10000
#define  NUM_ROWS_IN_WINDOW 10000

#include "storage.h"
#include "alisp.h"
#include "callout.h"

unsigned int SWINTYPE; /*TODO: 2013-10-08
 Since there is no value available, I have to
 modified register_swincell function*/

/*Slas window*/
struct SLWindow {
  double *buffer; 
/*list of rows. Each row i has fixed size (rowsize).Therefore the next row i+1
  is from buffer[i*rowsize] to buffer[(i+1)*rowsize]
  Access a nth element in row i:
  buffer[i*rowsize + nth]*/
  long   startts; 
  /*when the window starts. This is timestamp generated from machine and sent
    over network*/
  unsigned int count;
  double sum;
  double min;
  double max;
};

void resetSLWindow(struct SLWindow *window);

void initWindow(struct SLWindow *window, unsigned int buffersize);

oidtype addRowToSLWindow(struct SLWindow *window, oidtype orow, 
			unsigned int rowsize, 
			unsigned int indexedpos,
			a_callcontext cxt);

#endif


