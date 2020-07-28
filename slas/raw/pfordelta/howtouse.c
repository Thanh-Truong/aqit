#include<stdio.h>
#include<stdlib.h>
#include<limits.h>
#include<string.h>
#include "pfordelta.h"
#include "s16.h"
#include "coding_policy_helper.h"
#include "coding_policy.h"

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

void test_compression() {
  int num_blocks = 2;
  int size = 130;
  unsigned int ay[130] = {1,0,1,1,1,1,1,0,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0};
  unsigned int *array=NULL;
  unsigned int *decompressor_out=NULL;
  unsigned int *compressor_out=NULL;

  int a, b, i;

  array = malloc(sizeof(unsigned int)*_block_size*num_blocks);
  memcpy(array, ay, size);
  printf("size array: %lu\n", sizeof(ay)/sizeof(unsigned int));
  printf("size compressor out: %d\n", (int) CompressedOutBufferUpperbound(_block_size) * num_blocks);
  printf("size decompressor out: %d\n", (int) UncompressedOutBufferUpperbound(_block_size * num_blocks));

  compressor_out = malloc( sizeof(unsigned int) * CompressedOutBufferUpperbound(_block_size) * num_blocks);
  a = compress_pfordelta(array, compressor_out, size, _block_size);
  for(i = 0; i < a; i++) {
    //print_binary(compressor_out[i]);
  }
  printf("space used by pfordelta: %d\n", a);
  free(compressor_out);
  free(array);
  return;

  *decompressor_out = (unsigned int*) malloc( sizeof(unsigned int) * UncompressedOutBufferUpperbound(_block_size * num_blocks));
  printf("========== decompressing ==============\n");
  b = decompress_pfordelta(compressor_out, decompressor_out, size, _block_size);
  printf("printing\n");
  for(i = 0; i < size; i++) {
  //  printf("%u -> %u\n", array[i], decompressor_out[i]);
  }

  printf("a: %d\nb: %d\n", a, b);
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
  unsigned int base;
  base = 1000000000;
  for (i = 0; i < 128; i ++){
    input[i] = 1000000000 + i - base;
  }

  i = 0;
  coded = (unsigned int *) malloc( size * sizeof(unsigned int) );
  output = (unsigned int *) malloc( size * sizeof(unsigned int) );
  //printf("coded = %X\n", coded);
  //printf("output = %X\n", output);
  newsize = compress_pfordelta(input, coded, size, 32);
  finalsize = decompress_pfordelta(coded, output, size, 32);

  printf("Normal size: %d\n", size);
  printf("Compress size: %d\n", newsize);
  printf("Consumed size: %d\n", finalsize);
  for(i = 0; i < size; i++) {
    printf("%u -> %X -> %u", input[i] + base, coded[i], output[i] + base);
    if (input[i] + base == output[i] + base) {
      printf("\n");
    } else {
      printf("WRONG \n");
    }
  }
}

void test_s16() {
  //unsigned int input[] = {232223,2,3,4,5,6,7,8,9,10};
  unsigned int input[128];
  unsigned int *coded;
  unsigned int *output;

  int size = 128;
  int newsize;
  int finalsize;
  int i;

  for (i = 0; i < 128; i ++){
    input[i] =  4294967295 - i;
  }
  i = 0;
  coded = (unsigned int *) malloc( size * sizeof(unsigned int) );
  output = (unsigned int *) malloc( size * sizeof(unsigned int) );
  //printf("coded = %X\n", coded);
  //printf("output = %X\n", output);
  newsize = s16_compress(input, coded, size);
  finalsize = s16_decompress(coded, output, size);

  printf("Normal size: %d\n", size);
  printf("Compress size: %d\n", newsize);
  printf("Consumed size: %d\n", finalsize);
  for(i = 0; i < size; i++) {
    if (input[i] != output[i]){
      printf("Wrong");
    }
    //printf("%u -> %X -> %u\n", input[i], coded[i], output[i]);
  }
}

// Example of usage
int main(int argc, char *argv[]) {
  //test_compression();
  //test_pfordelta();
  test_s16();
  /*int i;
  int a;
  unsigned int p[128];
  unsigned int t[128];
  p[0] = 2;
  p[1] = 2;
  p[2] = 3;
  p[3] = 0xffff;  
  a = compress_pfordelta(p,t,4,32);
  
  printf("new size: %d\n",a);
  for (i = 0; i < a; i++ ) { print_binary(t[i]); printf("\n"); };*/
  return 0;
}
