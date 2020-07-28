/*****************************************************************************
 * AMOS2
 * 
 * Author: (c) 2012 Thanh Truong, UDBL
 * $RCSfile: main.c,v $
 * $Revision: 1.3 $ $Date: 2012/05/24 18:04:14 $
 * $State: Exp $ $Locker:  $
 *
 * Description: Simulator main
 ****************************************************************************/
#include "slaslogger.h"
#define assert_block(blockno, lbv) {if (lbv->offset_start != (blockno - 1) * 400000 \
					&& lbv->offset_end != (blockno) * 400000) \
      { printf("Block %d was not retrieved correctly (%llu, %llu) \n", \
	       blockno, lbv->offset_start,lbv->offset_end);} \
    else printf("Block %d start %llu and end %llu \n", blockno, lbv->offset_start, lbv->offset_end);} 

 
void testGenerate() {
        /*4 is indexed position = mv*/
	amosql("slaslogger1(csv_file_tuples('raw/data/measuredB.txt'), 4, 5, 'measuredB.bin');", FALSE);
	/*5 is number of colums*/
	amosql("readblogfile('measuredB.bin', 5);", FALSE);
}
void testGetRandom() {


}

int printBlockInfo(LBKey k, struct LBValue* lbv,  void *xa){
  assert_block((int)k, lbv);
  return TRUE;
}

void testMap() {
	// Retrieve the first block info
	lofixP_map(&g_lx[0], (LBKey) 100, (LBKey) 105, (LofixPMapper) printBlockInfo, NULL, NULL);	
}

void testRelease() {
  //lofixP_release(&g_lx[0]);
}







