#include <math.h>
#include <float.h>
#include <stdio.h>
#include <stdlib.h>
#include "../../common/slas.h"

void resetSLWindow(struct SLWindow *window) {
  //No need to empty, the buffer will be overwritten anyway
  // Reset statistic
  window->startts = 0;
  window->count = 0;
  window->sum = 0;
  window->min = DBL_MAX;
  window->max = -DBL_MAX;
}

void initWindow(struct SLWindow *window, unsigned int buffersize) {
  resetSLWindow(window);
  window->buffer = (double*) malloc(buffersize);
}
/*SLWindow is a data structure to keep statistic and info of logged window*/
oidtype addRowToSLWindow(struct SLWindow *window, oidtype orow, 
			 unsigned int rowsize, unsigned int indexedpos,
			 a_callcontext cxt) {
  unsigned int i;
  double v;
  // continue filling in the window
  for ( i = 0; i < rowsize ; i ++) {
    // get double value from array referenced by orow
    IntoDouble(dr(orow, arraycell)->cont[i], v, cxt->env); 
    // add v into row, which is packed in window
    // there is no physical row. All rows needed are accessed by its index
    window->buffer[window->count * rowsize + i] = v;
    // update window statistic
    if (i == indexedpos){
      // Min
      if (window->min > v){
	window->min = v;
      }
      // Max
      if (window->max < v) {
	window->max = v;
      }
      // Sum
      window->sum += v;    
    }
  }
  // Count
  window->count++;
  return nil;
}

