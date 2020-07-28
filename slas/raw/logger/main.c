#include "logger.h"
#include "config.h"

#define LOG_FILE "example.bin"

void testBasic(double data[][COLS]);

int testWriteRows(double data[][COLS]) {
	// File handle, see http://www.cplusplus.com/reference/cstdio/fopen/
	FILE* fh;
	
	// Some internal variables
	int i, res, total;
	fh = fopen(LOG_FILE, "w+b");
	assert_open(fh);
	
	res = TRUE;
	total = 0;
	for(i = 0; i < ROWS && i != UNDEFINED; i++) {
		res = writeRow(fh, data[i], ATTRIBUTE_SIZE_IN_BYTES, COLS);
		total = total + res;
	}
	if (total == COLS * ROWS) {
		printf("TestWriteRows was OK \n");
	} else {
		printf("TestWriteRows was not OK \n");
	}
	fclose(fh);
	return TRUE;
	
}
int testSingleRow(const double *orgdata, const double* rdata) {
	int res = TRUE;
	int j;
	for(j = 0; j < COLS; j++) {
		slas_print("%.3f   ", rdata[j]);
		if(rdata[j] != orgdata[j]){
			slas_print("WRONG !!! Original %f and read value %f \n", rdata[j], orgdata[j]);
			res = FALSE;
		}
	}
	slas_print("\n");
	return res;	
}

int testReadRows(double data[][COLS]) {
	FILE *fh;
	int res, i, match;
	double* rdata;
	
	// Read the file again and print all rows
	fh = fopen(LOG_FILE, "rb");
	assert_open(fh);
	
	res = TRUE;
	match = TRUE;
	alloca_row(rdata, ROWSIZE_IN_BYTES);
	for(i = 0; i < ROWS && i != UNDEFINED && match; i++) {
		res = readRow(fh, rdata, ATTRIBUTE_SIZE_IN_BYTES, COLS);
		if (res == ROWSIZE_IN_BYTES) {
			match = testSingleRow(data[i], rdata);
		}
	}
	
	if (match == TRUE) {
		printf("TestReadRows was OK \n");
	} else {
		printf("TestReadRows was not OK \n");
	}
	free(rdata);
	fclose(fh);
	return TRUE;
}

int testSkipRows(double data[ROWS][COLS]) {
	FILE *fh;
	int res, match;
	double* rdata;
	spos_t pos;
	
	// Read the file again and print all rows
	fh = fopen(LOG_FILE, "rb");
	assert_open(fh);
	
	res = TRUE;
	match = TRUE;
	// Allocate a row
	alloca_row(rdata, ROWSIZE_IN_BYTES);
	// Skip the first row 0 to row 1
	pos = sftell(fh);
	skipRows(fh, pos, 1, ROWSIZE_IN_BYTES);	
	res = readRow(fh, rdata, ATTRIBUTE_SIZE_IN_BYTES, COLS); /*We should get row 1 and pos is changed to row 2*/
	if (res == ROWSIZE_IN_BYTES) {
		// We should get row 1
		match = testSingleRow(data[1], rdata);
	}
	if (match == FALSE) {
		printf("TesSkipRows was not OK \n");
		return FALSE;
	} 
	// Skip the row 2 to row 3
	pos = sftell(fh);
	skipRows(fh, pos, 1, ROWSIZE_IN_BYTES);	
	res = readRow(fh, rdata, ATTRIBUTE_SIZE_IN_BYTES, COLS); /*We should get row 3 and pos is changed to row 4*/
	if (res == ROWSIZE_IN_BYTES) {
		match = testSingleRow(data[3], rdata);
	}
	if (match == TRUE) {
		printf("TestSkipRows was OK \n");
	} else {
		printf("TestSkipRows was not OK \n");
	}
	fclose(fh);
	free(rdata);
	return TRUE;
}

int testWriteBuffer(double data[][COLS]) {
	// File handle, see http://www.cplusplus.com/reference/cstdio/fopen/
	FILE* fh;
	//LofixP* lx;
	// Some internal variables
	int i, res;
	fh = fopen(LOG_FILE, "w+b");
	assert_open(fh);
	
	res = TRUE;
	// Create an log file index
	//lx = lofixP_create();
	for(i = 0; i < NUM_BLOCKS && i != UNDEFINED; i++) {
		res = writeBuffer(fh, data[NUM_ROWS_IN_BLOCK*i], /*start of a block*/
			NUM_ROWS_IN_BLOCK,
			COLS,
			ATTRIBUTE_SIZE_IN_BYTES);
	}
	fclose(fh);
	return TRUE;
	
}


int testReadBuffer(double data[ROWS][COLS]) {
	// File handle, see http://www.cplusplus.com/reference/cstdio/fopen/
	FILE* fh;
	double* rblock;
	// Some internal variables
	int i, j, res;
	fh = fopen(LOG_FILE, "rb");
	assert_open(fh);
	
	rblock =  (double*) malloc(ATTRIBUTE_SIZE_IN_BYTES * COLS * NUM_ROWS_IN_BLOCK);
	if (rblock == NULL) {slas_print("Malloc error !!"); return FALSE;}
	
	res = TRUE;
	for(i = 0; i < NUM_BLOCKS && i != UNDEFINED; i++) {
		res = readBuffer(fh, rblock, /*start of a block*/
			NUM_ROWS_IN_BLOCK,
			COLS,
			ATTRIBUTE_SIZE_IN_BYTES);

		for(j = 0; j < NUM_ROWS_IN_BLOCK; j++) {
			testSingleRow(data[NUM_ROWS_IN_BLOCK*i + j], (rblock + j*COLS));
		}
		
	}
	fclose(fh);
	return TRUE;	
}

int main() {
	// Rows in CVS files
	double  data [ROWS][COLS] = 
	{
		// Block 0
		{10.285, 20.345, 30.439, 40.518, 50.111},
		{20.267, 20.356, 20.412, 20.509, 50.121},
		{30.209, 30.318, 30.411, 30.575, 50.131},
		{40.209, 40.318, 40.411, 40.575, 50.141},
		{50.809, 50.301, 50.400, 50.675, 50.151},
		// Block 1
		{11.285, 21.345, 31.439, 41.518, 51.111},
		{21.267, 21.356, 21.412, 21.509, 51.121},
		{31.209, 31.318, 31.411, 31.575, 51.131},
		{41.209, 41.318, 41.411, 41.575, 51.141},
		{51.809, 51.301, 51.400, 51.675, 51.151},
		// Block 2
		{12.285, 22.345, 32.439, 42.518, 52.111},
		{22.267, 22.356, 22.412, 22.509, 52.121},
		{32.209, 32.318, 32.411, 32.575, 52.131},
		{42.209, 42.318, 42.411, 42.575, 52.141},
		{52.809, 52.301, 52.400, 52.675, 52.151},
		// Block 3
		{13.285, 23.345, 33.439, 43.518, 53.111},
		{23.267, 23.356, 23.412, 23.509, 53.121},
		{33.209, 33.318, 33.411, 33.575, 53.131},
		{43.209, 43.318, 43.411, 43.575, 53.141},
		{53.809, 53.301, 53.400, 53.675, 53.151},
		// Block 4
		{14.285, 24.345, 34.439, 44.518, 54.161},
		{24.267, 24.356, 24.412, 24.509, 54.171},
		{34.209, 34.318, 34.411, 34.575, 54.181},
		{44.209, 44.318, 44.411, 44.575, 54.191},
		{54.809, 54.301, 54.400, 54.675, 54.181}};

		testBasic(data);		
		slas_print("-----------Testing WriteRows-------------------- \n");
		testWriteRows(data);	
		slas_print("-----------Testing ReadRows--------------------- \n");
		testReadRows(data);	
		slas_print("-----------Testing SkipRows--------------------- \n");
		testSkipRows(data);
		slas_print("-----------Testing WriteBlock--------------------- \n");
		testWriteBuffer(data);
		slas_print("-----------Testing ReadBlock--------------------- \n");
		testReadBuffer(data);
		slas_print("Testing ends \n");
#if defined (_MSC_VER)
		printf("Visual Studio version %d and %lu \n", _MSC_VER, _INTEGRAL_MAX_BITS);
#endif

#if defined (_POSIX_)
		printf("POSIX %d \n", _POSIX_);
#endif
		return 1;
}
