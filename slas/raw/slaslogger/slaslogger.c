/* SVN FILE: $Id$ */ 
/** 
 * Project Name:  SLAS RAW
 * 
 * @package    className 
 * @subpackage    subclassName 
 * @author         $Author$ 
 * @copyright    $Copyright$ 
 * @version    $Rev$ 
 * @lastrevision    $Date$ 
 * @license        $License$ 
 * @filesource    $URL$ 
 */  

#include <math.h>
#include <float.h>
#include <stdio.h>
#include <stdlib.h>

#include "slaslogger.h"
#include "../../common/slas.h"

/*#undef NUM_ROWS_IN_BLOCK
#define  NUM_ROWS_IN_BLOCK 10000
#define  NUM_ROWS_IN_WINDOW 2500
*/
int flushWindow(struct WriterInfo* winf){
  int endblock = FALSE;
  int startblock = FALSE;
  struct SLWindow* window = winf->window;
  int totalWrite = 0;
  // Window is not empty ?
  if (winf->rowcount != 0) { 
    winf->nwrite = winf->nwrite + 1;
    slas_print("...Window # %d \n", winf->nwrite);
		
    startblock = (winf->nwrite % (winf->nrows_per_block / winf->nrows_per_window) == 1) ? 
      TRUE:FALSE;
    endblock = (winf->nwrite % (winf->nrows_per_block / winf->nrows_per_window) == 0) ? 
      TRUE:FALSE;
		
    if (startblock == TRUE){
      winf->blockno = winf->blockno + 1;
      winf->offset_startblock = sftell(winf->fh) ;
      printf("Startblock here %llu.... ",winf->offset_startblock );
    }

    // Write to file
    totalWrite = writeBuffer(winf->fh, window->buffer, winf->rowcount, 
			     winf->ncolumns, winf->attribute_size);
    // reset window : buffer and statistic
    resetSLWindow(window);

    if (endblock == TRUE){
      struct LBValue *lbv;
      winf->offset_endblock = sftell(winf->fh);
      printf("End block %llu....\n", winf->offset_endblock);
      lbv = (struct LBValue*) malloc(sizeof(*lbv));
      // Indexing the complete block
      lbv->indexedPos = winf->indexedpos;
      lbv->maxIndexedAtt = 0;
      lbv->minIndexedAtt = 0;
      lbv->offset_start = winf->offset_startblock;
      lbv->offset_end = winf->offset_endblock;

      lofixP_insert(winf->lxp, (void*) winf->blockno, lbv, NULL);
    }

  }	
  winf->rowcount = 0; 
  return totalWrite;
}

/*- Adding row to window
  - Collecting statistic per window (sum, count, max, min)
*/
oidtype __addRowToWindow(struct WriterInfo* winf, oidtype orow, int rowsize, a_callcontext cxt) {
  int i;
  double v;
  struct SLWindow* window = winf->window;
  
  // continue filling in the window
  for (i = 0; i < rowsize ; i ++) {
    // get double value from array referenced by orow
    IntoDouble(dr(orow, arraycell)->cont[i], v, cxt->env); 
    // add v into row, which is packed in window
    // there is no physical row. All rows needed are accessed by its index
    window->buffer[winf->rowcount * rowsize + i] = v;
    // update window statistic
    if (i == winf->indexedpos){
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
      // We index every row just to see how big the index lofixS will be
      lofixS_insert(winf->lxs, v, sftell(winf->fh), NULL);
    }
  }
  // Count
  window->count++;
  return nil;
}
oidtype writetupleMapper(a_callcontext cxt, int width, oidtype res[],void *xa)
{ 
  oidtype orow; // original row from stream
  unsigned int rowsize;
  struct WriterInfo* winf;

  winf = (struct WriterInfo*) xa;
  orow = res[0];
  if (arrayp(orow)) 
    {
      /*Start filling the window*/
      if (winf->rowcount == 0) {
	slas_print("Filling the window ...");
      }
      rowsize = dr(orow, arraycell)->size; 
      if (rowsize != winf->ncolumns) {
	printf("there is a mismatch between rowsize and number of columns\n");
	return nil; // there is a mismatch between rowsize and number of columns
      }

      // continue filling in the window
      __addRowToWindow(winf, orow, rowsize, cxt);

      // Increase the rowcount
      winf->rowcount = winf->rowcount + 1 ;

      /*If the window is full, write it down to log file*/
      if (winf->rowcount == winf->nrows_per_window) {
	slas_print("FULL --> Write ");
	flushWindow(winf);
      }
    }	
  return nil;
}



/*----------------------------------------------------------------------------
 *
 *-----------------------------------------------------------------------------*/
oidtype slas_write_indexed_logfilebbf(a_callcontext cxt)
{
  oidtype ofname;
  oidtype b;
  oidtype oidxpos;
  oidtype ocols;
  char *logfilename;
  FILE*fh;
  struct WriterInfo winf;
  struct SLWindow window;
  unsigned int indexedpos, cols;
  LofixP *lxp;
  LofixS *lxs;

  {unwind_protect_begin;	
    //Unbox filename and open file
    ofname = a_arg(cxt, 4);
    IntoString(ofname, logfilename, cxt->env);
	
    fh = fopen(logfilename, "w+b");
    assert_open(fh);
	
    //Unbox a bag
    b = a_arg(cxt, 1);

    //Unbox indexed position 
    oidxpos = a_arg(cxt, 2);
    IntoInteger(oidxpos, indexedpos, cxt->env);

    //Unbox total columns 
    ocols = a_arg(cxt, 3);
    IntoInteger(ocols, cols, cxt->env);

    // Prep some writer instruction	
    winf.fh = fh;	
    winf.nrows_per_block = NUM_ROWS_IN_BLOCK;
    winf.nrows_per_window = NUM_ROWS_IN_WINDOW; // this will cause 2 write per block
    winf.ncolumns = cols;
    winf.attribute_size = ATTRIBUTE_SIZE_IN_BYTES;

    // Initialize Window
    initWindow(&window, winf.nrows_per_window * winf.ncolumns *winf.attribute_size);
    winf.window = &window;

    winf.rowcount = 0;
    winf.nwrite = 0;
    winf.indexedpos = indexedpos;
    winf.blockno = 0;
    winf.offset_endblock = winf.offset_startblock = 0;
    // Prep lofixP index
    lxp = lofixP_create();
    strcpy(lxp->logfilename, logfilename);
    winf.lxp = lxp;
    // Prep lofixS index
    lxs = lofixS_create();
    winf.lxs = lxs;

    // Loop over the bag and write the log file
    a_mapbag(cxt, b, writetupleMapper, &winf);

    // If the last filling did not make the window full, there was no write.
    // We have to flush the partial window to file if it is 
    flushWindow(&winf);
	
    // last final step. Store the lx index
    g_lx[0] = *lxp;
    unwind_protect_catch; 
    fclose(fh); 
    free(window.buffer);
    free(lxp);
    free(lxs);
    return t;
    unwind_protect_end;	
  }
  return t;
}
