#include<stdio.h>
#include<stdlib.h>
#include<limits.h>
#include<string.h>
#include<stdint.h>
#include "../pfordelta/pfordelta.h"
#include "../pfordelta/s16.h"
#include "../pfordelta/coding_policy_helper.h"
#include "../pfordelta/coding_policy.h"

#define DESC_POINTER_SIZE   4
#define DESC_STATUS_SIZE    1

#define allocate_array(pa) {pa = (unsigned char*) calloc(DESC_STATUS_SIZE \
							 + DESC_POINTER_SIZE \
							 + arraysize * sizeof(unsigned int), 4);}

struct MetaCa {
  unsigned int count ;    // how many arrays in the list
  unsigned char* pa;      // pointer to the head array
  unsigned int arraysize; // size of array
};

/*Block size must be a multiple of 32*/
struct MetaCa* metaca_create(unsigned int blocksize);

void metaca_insert(struct MetaCa* mca, unsigned int element);
void metaca_print(struct MetaCa* mca);
void metaca_release(struct MetaCa* mca);
