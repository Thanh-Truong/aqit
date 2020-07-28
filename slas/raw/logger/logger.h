#ifndef _LOGGER_H_
#define _LOGGER_H_

#include "stdlib.h"
#include "stdio.h"
#include "stdarg.h"
#include "string.h"
#include "../../common/slas_portable.h"

#define  TRUE 1
#define  FALSE 0
#define  NSUCCESS -1
#define  UNDEFINED -1

/*assert file stream*/
#define  assert_write(fh) {if (ferror(fh)) slas_print("Error writing file \n");}
#define  assert_read(fh) {if (ferror(fh)) slas_print("Error reading file \n");}
#define  assert_open(fh) {if (fh == NULL) {slas_print("Error openning file \n"); return UNDEFINED;}}
#define  assert_close(fh) {if (ferror(fh)) slas_print("Error closing file \n");}
#define  assert_malloc(ptr) {if (ptr==NULL) {slas_print("Error in malloc \n"); return FALSE;}}
#define  alloca_row(ptr, rowsize) {ptr = (double*) malloc(rowsize); assert_malloc(ptr);}
void slas_print(char* fmt, ...);

/* write an array data as a binary row
  - fh   : file handle
  - row : an array hosting row to be written
  - attsize : size of a single attribute in the row
  - ncolumns : number of columns in a single row
  return 
*/
int writeRow(FILE *fh, double* row, size_t asize,  size_t ncolumns);

/* read binary row into an array
  - fh   : file handle
  - row : an array hosting read row
  - attsize : size of a single attribute in the row
  - ncolumns: number of columns in a single row
*/
int readRow(FILE *fh, double* row, size_t attsize, size_t ncolumns);

/*Given a file position spos_t position, this function
will set the current file pointer to a new positions

The new position is returned if success. Otherwise*/
spos_t skipRows(FILE *fh, const spos_t position, size_t rows, size_t rowsize);

/*Write block of data (2D array)
  - nrows : number of rows in a block
  - ncolumns : number of columns per row
  - attsize  : size of a single attribute (in bytes)
  - idx : the index to be updated
, size bsize and updating block meta-data on the index idx*/
int writeBuffer(FILE *fh, const double buffer[], size_t nrows, size_t ncolumns, size_t attsize);

/*Read block into rdata using idx as hint*/
int readBuffer(FILE *fh, double block[], size_t nrows, size_t ncolumns, size_t attsize);

#endif
