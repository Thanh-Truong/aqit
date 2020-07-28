#ifndef _SLAS_LOGGER_CONFIG_
#define _SLAS_LOGGER_CONFIG_

#define  NUM_ROWS_IN_BLOCK 5
#define  NUM_BLOCKS 5

#define  ROWS  (NUM_ROWS_IN_BLOCK*NUM_BLOCKS)
#define  COLS  5

#define  ATTRIBUTE_SIZE_IN_BYTES sizeof(double)
#define  ROWSIZE_IN_BYTES (ATTRIBUTE_SIZE_IN_BYTES * COLS)

// Positions of log elements
#define  M_POS 0    // machine
#define  S_POS 1    // sensor
#define  BT_POS 2   // begin time
#define  ET_POS 3   // end time
#define  MV_POS 4   // measured value
#endif