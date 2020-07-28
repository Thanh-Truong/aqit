#include "read_blogfile.h"

oidtype readblogfilebbf(a_callcontext cxt)
{
  oidtype file = a_arg(cxt, 1);
  oidtype o_cols = a_arg(cxt, 2);
  oidtype *acont;

  char* filename;
  FILE* fh;
  double* rdata;
  int nread;
  int cols, j;
 
	
  IntoString(file, filename, cxt->env);
  IntoInteger(o_cols, cols, cxt->env);
  fh = fopen(filename, "rb");
  assert_open(fh);
  alloca_row(rdata, cols * sizeof(double));
  {unwind_protect_begin;
    for(;;)
      {
	nread = readRow(fh, rdata, sizeof(double), cols);
	if (nread == cols) 
	  {
	    oidtype row = nil;
	    // convert rdata to row
	    a_setf(row, new_array(cols,nil));
	    acont = dr(row,arraycell)->cont;
	    for(j=0; j<cols; j++) {
	      a_let(acont[j], mkreal(rdata[j]));
	    }
	    a_bind(cxt,3, row);
	    a_result(cxt);
	    a_free(row);
	  } else {
	  break;
	}
      }
    unwind_protect_catch;
    fclose(fh);
    free(rdata);
    unwind_protect_end;}
  return nil;
}
