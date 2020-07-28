#include "write_blogfile.h"
#include "scsq.h"
#include "swinCh.h"

/*Write raw stream*/
oidtype writeblogfilebbf(a_callcontext cxt) {
  return nil;
}

oidtype bufferit(bindtype env, oidtype orow, oidtype wstat, 
		 unsigned int cols, double* buffer, int count) {
  unsigned int i;
  double v;
  // continue filling in the window
  for (i = 0; i < cols ; i ++) {
    // get double value from array referenced by orow
    IntoDouble(dr(orow, arraycell)->cont[i], v, env); 
    // add v into row, which is packed in window
    // there is no physical row. All rows needed are accessed by its index
    buffer[count * cols + i] = v;
  }
  return nil;
}

/*======================================================
  WriteWindowInfo
  ========================================================*/
struct WriteWindowInfo{
  unsigned int indexedpos;
  unsigned int rowsize;
  unsigned int count;
  char *logfilename;
  FILE *logfile;
};
typedef struct swincell swincell;


oidtype writeWindow0(a_callcontext cxt, int width, oidtype res[],void *xa)
{ 
  oidtype oswin = nil;
  double *buffer;
  struct swincell *scell;
  struct WriteWindowInfo *winfo = (struct WriteWindowInfo *) xa;
  oidtype l = nil; // list of all elements in the Swin 
  int i;
  oidtype wstat = nil;

  // Initialize
  oswin = res[0];
  OfType(oswin, SWINTYPE, cxt->env);
  wstat = make_winstats0fn(cxt->env);

  // STEP 0 Buffer the window and collec statistic 
  scell = dr(oswin, swincell);
  buffer = (double*) malloc(scell->size      // total elements in the window
			    * winfo->rowsize // total columns
			    * sizeof(double));
  a_setf(l, hd(scell->extent));
  for(i = 0; i < scell->size; i++){
    bufferit(cxt->env, fhd(l), wstat, winfo->rowsize, buffer, i);
    a_setf(l, ftl(l));
  }
  // STEP 1 Persit the window (all events in the windows are buffered) into log file
  writeBuffer(winfo->logfile, buffer, scell->size, 
	      winfo->rowsize, sizeof(double));
 
  // STEP 2 Store windows statistic into B-tree index  
  // STEP 3 Persit the index, close the log file and open a new one if needed
  winfo->count++; // increase total windows of the log file
  // Finalize used resources
  free(buffer);
  a_free(l);
  return wstat;
}
oidtype writeWindowMapper(a_callcontext cxt, int width, oidtype res[],void *xa)
{
  oidtype r = writeWindow0(cxt,width, res,xa);
  // Emit a stream of WinStats
  a_bind(cxt, 5, r);
  a_result(cxt);
  return nil;
}

/*;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Write stream of windows
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;*/
oidtype write_window_blogfilebbf(a_callcontext cxt) {
  oidtype ofname;
  oidtype s;
  oidtype oidxpos;
  oidtype ocols;
 
  struct WriteWindowInfo winfo;
  
  {unwind_protect_begin;	
    //Unbox a stream
    s = a_arg(cxt, 1);

    //Unbox indexed position 
    oidxpos = a_arg(cxt, 2);
    IntoInteger(oidxpos, winfo.indexedpos, cxt->env);

    //Unbox total columns 
    ocols = a_arg(cxt, 3);
    IntoInteger(ocols, winfo.rowsize, cxt->env);

    //Unbox filename and open file
    ofname = a_arg(cxt, 4);
    IntoString(ofname, winfo.logfilename, cxt->env);
    
    winfo.logfile = fopen(winfo.logfilename, "w+b");
    assert_open(winfo.logfile);

    // Loop over the bag and write the log file
    winfo.count = 0;
    a_mapbag(cxt, s, writeWindowMapper, &winfo);

    unwind_protect_catch; 
    fclose(winfo.logfile); 
    unwind_protect_end;	
  }
  return nil;
}
/*Write stream of windows*/
oidtype write_window_blogfile1bbf(a_callcontext cxt) {
  oidtype ofname;
  oidtype w;
  oidtype oidxpos;
  oidtype ocols;
  oidtype res[1];
  oidtype wstat;
 
  struct WriteWindowInfo winfo;
  //printf("Start properly \n");

  {unwind_protect_begin;	
    //Unbox a window
    w = a_arg(cxt, 1);

    //Unbox indexed position 
    oidxpos = a_arg(cxt, 2);
    IntoInteger(oidxpos, winfo.indexedpos, cxt->env);

    //Unbox total columns 
    ocols = a_arg(cxt, 3);
    IntoInteger(ocols, winfo.rowsize, cxt->env);

    //Unbox filename and open file
    ofname = a_arg(cxt, 4);
    IntoString(ofname, winfo.logfilename, cxt->env);
    
    winfo.logfile = fopen(winfo.logfilename, "a+b");
    assert_open(winfo.logfile);
 
    // Loop over the bag and write the log file
    winfo.count = 0;
    res[0] = w;
    wstat = writeWindow0(cxt, 1, res, &winfo);
    //printf("Winfo indexed pos %d, cols %d filename %s \n", winfo.indexedpos, winfo.rowsize,
    //winfo.logfilename);
    unwind_protect_catch; 
    fclose(winfo.logfile);
    unwind_protect_end;	
  }
  // Emit a stream of WinStats
  //printf("Close properly \n");
  a_bind(cxt, 5, wstat);
  a_result(cxt);
  return nil;
}

oidtype xxxbbf(a_callcontext cxt) {
  printf("Do it like it is no tomorrow \n");
  a_bind(cxt, 3, make_winstats0fn(cxt->env));
  a_result(cxt);
  return nil;
}

