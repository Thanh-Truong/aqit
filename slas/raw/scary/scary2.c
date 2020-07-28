#include "scary.h"
#include "scary2.h"

/*Clear the 1st bit of the status*/
unsigned char get_slots(unsigned char *pa) {
   return *pa & ~((1<<7)); 
}

/*Return if the array is compressed or not*/
unsigned char is_compressed(unsigned char *pa) {
  return *pa & (1 << 7); 
}

/*Set array is compressed*/
void set_compressed(unsigned char *pa) {
  *pa = *pa | (1 << 7);
}
/*Increase slots*/
void increase_slots(unsigned char *pa){
  unsigned char compressed = *pa & (1<<7);
  unsigned slots = get_slots(pa);
  *pa = slots + 1;
  if (compressed != 0) {
    set_compressed(pa);
  }
}

/*Move to values array*/
unsigned int* values_array(unsigned char *pa) {
  return (unsigned int*)(pa + DESC_STATUS_SIZE + DESC_POINTER_SIZE);
}

/*ca is history of na 
uninptr_t data type for unsigned int pointer 
this could be different on Windows/Unix
*/
void link_previous(unsigned char *na, unsigned char *ca) {
  unsigned int *previous = (unsigned int*)(na + DESC_STATUS_SIZE);
  printf("previous %u ca %u", previous, ca);
  previous[0]=(void*)ca;
  printf("previous[0] %u \n", previous[0]);
} 

unsigned char* get_previous(unsigned char *pa) {
  unsigned int *p = (unsigned int*)(pa + DESC_STATUS_SIZE);	
  return (p[0]==0)?NULL:(unsigned char*)((uintptr_t)p[0]);
}


struct MetaCa* metaca_create(unsigned int arraysize) {
  if ((arraysize % 32) == 0) {
    // Allocate head and its array
    struct MetaCa* mca;
    _scary_block_size_ = 32;
    
    mca = (struct MetaCa*) malloc(sizeof(*mca));
    // Here pa is a pointer of unsigned char. It enables accessing
    // any byte gned char status = *(pa + DESC_STATUS_SIZE);
    allocate_array(mca->pa);
    mca->count = 0;
    mca->arraysize = arraysize;
    return mca;
  }
  return NULL;
}

void metaca_compress_array(struct MetaCa *mca){
  unsigned char *ca; // compressed array
  unsigned char arraysize = mca->arraysize;
  int newsize;
  unsigned char *na; // new array
  printf("======compress======= ");
  allocate_array(ca);
  // copy it status
  memcpy(ca, mca->pa, DESC_STATUS_SIZE + DESC_POINTER_SIZE);
  // compress
  newsize = compress_pfordelta(values_array(mca->pa), 
			       values_array(ca), 
			       arraysize, _scary_block_size_);
  // reallocate to shrinking the unused space
  ca = (unsigned char *) realloc(ca, newsize * sizeof(unsigned int) 
				 + DESC_STATUS_SIZE 
				 + DESC_POINTER_SIZE);
  printf("Status (slots %u , compressed %u)\n", get_slots(ca), is_compressed(ca));
  // free uncompressed array
  free(mca->pa); 
  // update status
  set_compressed(ca);  
  // make a new array and link it 
  allocate_array(na);
  mca->pa = na;
  printf("na %u ca %u \n", na, ca);
  link_previous(na, ca); // use 4 bytes to point to ca
  mca->pa = na;
  mca->count++;
}
void metaca_insert(struct MetaCa* mca, unsigned int element)
{
  if (mca != NULL) {
    unsigned char slots = get_slots(mca->pa);
    unsigned int *vla = values_array(mca->pa);
    unsigned char arraysize = mca->arraysize;
    // Array is not full yet
    if (slots < arraysize) {
      printf("Before vla[%u]= %u ", slots, vla[slots]);
      vla[slots] = element;
      printf("After vla[%u] = %u", slots, vla[slots]);
      if (slots == arraysize - 1) {
	// Pro-active compression + spawn
	// Array is full ( slot 127 --> 0)
	printf(" Array is full !!\n");
	metaca_compress_array(mca);
      } else {
	increase_slots(mca->pa);
	printf(" Slot --> %u\n", get_slots(mca->pa));
      }

    }
  }
}

void metaca_print_array(unsigned char*pa, int headcount) {
  if (pa != NULL) {
    unsigned char *prev;
    printf("[#Array %d ", headcount);
    if (is_compressed(pa)) {
      printf(" Compressed ");
    } else {
      printf(" Uncompressed ");
    }
    printf(" slots: %d] \n", get_slots(pa));
    prev = get_previous(pa); 
    printf("Get previous %u \n", prev);
    if (prev != NULL){
      //metaca_print_array(prev, headcount -1 );
      printf("---Previous is %u \n", prev[0]);
    }
  }
}

/*Print out the linked list of compressed array in the reversed order
  which they were inserted*/
void metaca_print(struct MetaCa* mca) {
  if (mca != NULL) {
    printf("----Meta-----\n");
    printf("-Count: %d - \n", mca->count); 
    printf("-------------\n");
    if (mca->pa != NULL) {
      printf("    |    \n");
      printf("    |    ");
      metaca_print_array(mca->pa, mca->count);
    }
  }
}

void metaca_release(struct MetaCa* mca) {
}  
