#include<stdio.h>
#include<stdlib.h>
#include<limits.h>
#include<string.h>
#include "../pfordelta/pfordelta.h"
#include "../pfordelta/s16.h"
#include "../pfordelta/coding_policy_helper.h"
#include "../pfordelta/coding_policy.h"
#include "scary.h"

int _block_size = 128;

// Print unsigned integer in binary format with spaces separating each byte.
void print_binary(unsigned int num) {
  int arr[32];
  int i = 0;
  while (i++ < 32 || num / 2 != 0) {
    arr[i - 1] = num % 2;
    num /= 2;
  }

  for (i = 31; i >= 0; i--) {
    printf("%d", arr[i]);
    if (i % 8 == 0)
      printf(" ");
  }
}


void test_pfordelta() {
  //unsigned int input[] = {2322231,2,3,4,5,6,7,8,9,10};
  unsigned int input[128] = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,10,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,10,10,10,10,10,10,10,10};
  unsigned int *coded;
  unsigned int *output;
  
  int size = 128;
  int newsize;
  int finalsize;
  int i;

  coded = (unsigned int *) malloc( size * sizeof(unsigned int) );
  output = (unsigned int *) malloc( size * sizeof(unsigned int) );

  printf("========compression============\n");
  newsize = compress_pfordelta(input, coded, size, 32);
  printf("Normal size: %d\n", size);
  printf("Compress size: %d\n", newsize);
  printf("Reclaim the unused space %d \n", size - newsize);
  coded = (unsigned int *) realloc(coded, newsize * sizeof(unsigned int));
  printf("========decompression============\n");
  finalsize = decompress_pfordelta(coded, output, size, 32);
  printf("Consumed size: %d\n", finalsize);
  for(i = 0; i < size; i++) {
    if(input[i] != output[i]) {
      printf("%u ->compress but decompress-> %u\n", input[i], output[i]);
    }    
  }
  free(coded);
  free(output);
}

void test_binary(){
  /*  http://stackoverflow.com/questions/47981/how-do-you-set-clear-and-toggle-a-single-bit-in-c*/
   unsigned char *anchor;
   unsigned char *ch;
   unsigned int *pa;
   unsigned int i = 0;
   // allocate 128 * 4 bytes for array + 5 bytes for anchor
   ch = (unsigned char *) malloc(128 * sizeof(unsigned int) 
				 + 5*sizeof(unsigned char));
   // point anchor and pa to the right positions
   anchor = ch; 
   pa = (unsigned int*) (ch + 5);

   printf("Size of unsigned int anchor %lu \n", sizeof(*anchor));
   for(i = 0; i < 128; i++){
     pa[i] = i;
   }
   for(i = 0; i < 128; i++){
     if (pa[i] != i){
       printf("Wrong ");
     }
   } 
   printf("Test random access to pa: pa[0]=%u pa[40]=%u pa[51]=%u pa[127]=%u \n", pa[0], pa[40], 
	  pa[51], pa[127]);
}

void test_scary(){
  struct Scary *head;
  unsigned int i, numel;
  unsigned int value;
  head = scary_create(128);
  // number of elements
  numel = 128 * 100 + 35;

  for (i = 0; i < numel; i ++) {
    head = scary_insert(head, i); 
  }
  scary_print(head);
   
  for(i = 0; i < numel; i++){
    value = scary_get(head, i);
    if (value!= i){
      printf("      Warning !!scary[%d]=%u \n", i, value);
      break;
    }
  }
  //scary_release(head);
}

/*void test_metaca(){
  struct MetaCa *mca;
  unsigned int i, numel;
  mca = metaca_create(128);
  // number of elements
  numel = 128 + 2;

  for (i = 0; i < numel; i ++) {
    metaca_insert(mca, i); 
  }
  metaca_print(mca);
  metaca_release(mca);
}
*/
unsigned int* g() {
  volatile uintptr_t iptr = 0xdeadbeef;
  unsigned int *ptr = (unsigned int *)iptr;
  return ptr;
}
void print_binary8(uintptr_t num) {
  int arr[64];
  int i = 0;
  while (i++ < 64 || num / 2 != 0) {
    arr[i - 1] = num % 2;
    num /= 2;
  }

  for (i = 63; i >= 0; i--) {
    printf("%d", arr[i]);
    if (i % 8 == 0)
      printf(" ");
  }
}

// Example of usage
#define PTR_SIZE sizeof(unsigned char*)
void test_store_pointer_in_array(){
  int i = 0;
  unsigned char *a = malloc(12);
  unsigned char *b = malloc(12);
  unsigned char **c = (unsigned char**) malloc(PTR_SIZE);
  for(i = 0; i < 12; i++) {
    a[i] = i * 2 ;
    printf("a[%u] = %u \n", i, a[i]);
  }  
  memcpy(b+2, &a, PTR_SIZE);
 
  memcpy(c, b+2, PTR_SIZE);
  for(i = 0; i < 12; i++) {    
    printf("c[%u] = %u \n", i, *((*c) + i));
  }
  free(a);
  free(b);
  free(c);
}
int main(int argc, char *argv[]) {
  //test_pfordelta();
  test_scary();
  //test_binary();
  //test_metaca();
  //test_store_pointer_in_array();
  return 0;
}
