#include "logger.h"


void slas_print(char* fmt, ...)
{
	// Debug info will be printed out only in DEBUG_MODE
#ifdef DEBUG_MODE
	if (DEBUG_MODE) {
		va_list args;
		va_start(args,fmt);
		vprintf(fmt,args);
		va_end(args);
	}
#endif
}


int writeRow(FILE *fh, double* row, size_t attsize, size_t ncolumns){
	int totalWrite = UNDEFINED;
	if (fh != NULL && row != NULL) {
		totalWrite = fwrite(row, attsize, ncolumns, fh); /*array, element size, count, file pointer*/
		assert_write(fh);
		slas_print("WriteRow has written %d elements out of %d \n", totalWrite, ncolumns);
	}
	
	return totalWrite;
}


int readRow(FILE *fh, double *row, size_t attsize, size_t ncolumns){
	int totalRead = UNDEFINED;
	if (fh != NULL && row != NULL) {
		totalRead = fread(row, attsize, ncolumns, fh);
		assert_read(fh);
		slas_print("ReadRow has read %d elements out of %d \n", totalRead, ncolumns);
	}
	
	return totalRead;
}

/*Given a file position spos_t position, this function
will set the current file pointer to a new positions*/
spos_t skipRows(FILE *fh, const spos_t pos,size_t rows, size_t rowsize){
	spos_t npos;

	slas_print("SkipRows current row is %ld \n", pos/rowsize); 
	npos = pos + (rows * rowsize);
	slas_print("I want to move to row %ld \n", npos/rowsize);
	sfseek(fh, npos, SEEK_SET);
	// mess up npos to test
	npos = UNDEFINED;

	npos = sftell(fh);
	slas_print("SkipRow has changed pos to row %ld \n", npos/rowsize);
	return npos;
}
void printBlock(double* block, size_t nrows, size_t ncolumns)
{
	unsigned int i,j;
	for(i = 0; i < nrows; i++) {				
		for (j = 0; j < ncolumns ; j ++) {
			slas_print(" %.3f  ", block[i*ncolumns + j]);
		}
		printf("\n");		
	}
}


/*Write block of data, size bsize and updating block meta-data on the index idx
A block consits of several rows. It can be considered as a BIG row itself.

THIS IS NOT OPTIMAL !!!!!! but it is fine at the time being-- Thanh*/
int writeBuffer(FILE *fh, const double buffer[], size_t nrows, size_t ncolumns, size_t attsize)
{
	double *wbuffer;
	unsigned int totalWrite;

	wbuffer = (double*) malloc(attsize * ncolumns * nrows);
	if (wbuffer == NULL) {slas_print("Malloc error !!"); return FALSE;}
	// copy data
	memcpy(wbuffer, buffer, attsize * ncolumns* nrows);
	//printBlock(wblock, nrows, ncolumns);
	if (fh != NULL && wbuffer != NULL) {
		totalWrite = fwrite(wbuffer, attsize, nrows*ncolumns, fh); /*array, element size, count, file pointer*/
		assert_write(fh);
		slas_print("writeBlock has written %d elements out of %d \n", totalWrite, nrows*ncolumns);
	}
	free(wbuffer);
	return totalWrite;
}

/*Read block from file hinted by idx into rdata*/
int readBuffer(FILE *fh, double buffer[], size_t nrows, size_t ncolumns, size_t attsize)
{
	unsigned int totalRead;	
	if (fh != NULL && buffer != NULL) {
		totalRead = fread(buffer, attsize, nrows*ncolumns, fh); /*array, element size, count, file pointer*/
		assert_read(fh);
		slas_print("readBlock has read %d elements out of %d \n", totalRead, nrows*ncolumns);
		//printBlock(block, nrows, ncolumns);
	}
	return totalRead;
}