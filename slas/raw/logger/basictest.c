#include "logger.h"
#include "config.h"

void testPassing1DArray(double* rdata){
	if (rdata != NULL) {
		double a = rdata[0];
		double b = rdata[1];
		rdata[0] = b;
		rdata[1] = a;
	}	
}


void testPassing2DArray_1stMethod(double rdata[][COLS]){
	if (rdata != NULL) {	
		double a = (rdata[0])[0];
		double b = (rdata[0])[1];
		(rdata[0])[0] = b;
		(rdata[0])[1] = a;
	}	
}

void testPassing2DArray_2ndMethod(double (*rdata)[COLS]){
	if (rdata != NULL) {	
		double a = (rdata[0])[0];
		double b = (rdata[0])[1];
		(rdata[0])[0] = b;
		(rdata[0])[1] = a;
	}	
}

int testBasicWrite (double data[][COLS])
{
  FILE * pFile;
  double d1[COLS] = {10.285, 20.345, 30.439, 40.518};
  double d2[COLS] = {11.285, 21.345, 31.439, 41.518};
  pFile = fopen ("example.bin", "wb");
  fwrite (d1, ATTRIBUTE_SIZE_IN_BYTES, COLS, pFile); 
  fwrite (d2, ATTRIBUTE_SIZE_IN_BYTES, COLS, pFile); 

  fclose (pFile);
  return 0;
}

int testBasicRead(){
  FILE * pFile;
  long lSize;
  double * buffer;
  size_t result;

  pFile = fopen ( "example.bin" , "rb" );
  if (pFile==NULL) {fputs ("File error",stderr); exit (1);}

  // obtain file size:
  fseek (pFile , 0 , SEEK_END);
  lSize = ftell (pFile);
  rewind (pFile);

  slas_print("Size of double %d \n ", ATTRIBUTE_SIZE_IN_BYTES);
  slas_print("Size of file %d \n ", lSize);
  slas_print("# of Rows in file %d \n ", lSize/ROWSIZE_IN_BYTES);
  // allocate memory to contain the whole file:
  alloca_row(buffer,ROWSIZE_IN_BYTES);
  if (buffer == NULL) {fputs ("Memory error",stderr); exit (2);}
  slas_print ("Size of buffer %d \n ", ATTRIBUTE_SIZE_IN_BYTES * COLS);

  // copy the file into the buffer:
  result = fread (buffer,ATTRIBUTE_SIZE_IN_BYTES,COLS,pFile);
  if (result != COLS) {fputs ("Reading error 1 ",stderr); exit (3);}

  result = fread (buffer,ATTRIBUTE_SIZE_IN_BYTES,COLS,pFile);
  if (result != COLS) {fputs ("Reading error 2",stderr); exit (3);}
  /* the whole file is now loaded in the memory buffer. */

  // terminate
  fclose (pFile);
  free (buffer);
  printf("Testing malloc was ok \n");
  return TRUE;
}

void testBasic(double data[][COLS]) {
	slas_print("Before Passing 1D Array data[0][0]= %.3f and data[0][1] %.3f \n", data[0][0], data[0][1]);
	testPassing1DArray(data[0]);
	slas_print("After Passing 1D Array data[0][0]= %.3f and data[0][1] %.3f \n", data[0][0], data[0][1]);
	slas_print("-------------------------------------------------------------- \n");
	slas_print("Before Passing 2D Array data[0][0]= %.3f and data[0][1] %.3f \n", data[0][0], data[0][1]);
	testPassing2DArray_1stMethod(data);
	slas_print("After Passing 2D Array data[0][0]= %.3f and data[0][1] %.3f \n", data[0][0], data[0][1]);
	slas_print("-------------------------------------------------------------- \n");
	slas_print("Before Passing 2D Array data[0][0]= %.3f and data[0][1] %.3f \n", data[0][0], data[0][1]);
	testPassing2DArray_2ndMethod(data);
	slas_print("After Passing 2D Array data[0][0]= %.3f and data[0][1] %.3f \n", data[0][0], data[0][1]);
	slas_print("-------------------------------------------------------------- \n");
	slas_print("Before Passing 2D Array data[0][0]= %.3f and data[0][1] %.3f \n", data[0][0], data[0][1]);
	testPassing2DArray_2ndMethod(data);
	slas_print("After Passing 2D Array data[0][0]= %.3f and data[0][1] %.3f \n", data[0][0], data[0][1]);
	testBasicWrite(data);
	testBasicRead();

}