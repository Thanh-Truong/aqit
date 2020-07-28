#include<stdio.h>
#include<stdlib.h>
#include<limits.h>
#include<string.h>
#include "../pfordelta/pfordelta.h"
#include "../pfordelta/s16.h"
#include "../pfordelta/coding_policy_helper.h"
#include "../pfordelta/coding_policy.h"

unsigned int _scary_block_size_;
unsigned int _scary_array_size_;

#define DESC_POINTER_SIZE   sizeof(unsigned char*)
#define DESC_STATUS_SIZE    1
//From 2014-05-16 Revision 214, a very important change was made by Thanh
#define allocate_array(pa, arraysize) {pa = (unsigned char*) calloc(DESC_STATUS_SIZE \
							 + DESC_POINTER_SIZE \
							 + arraysize, sizeof(unsigned int));}

struct Scary {
  unsigned int arraysize; // maximum size of an array  
  unsigned int count;     // How many arrays in the linked list
  unsigned char* pa;      // pointer to the head array
};

/*Clear the 1st bit of the status*/
unsigned char get_slots(unsigned char *pa);

/*Return if the array is compressed or not*/
unsigned char is_compressed(unsigned char *pa);

/*Set array is compressed*/
void set_compressed(unsigned char *pa);

/*Increase slots*/
void increase_slots(unsigned char *pa);

void clear_compressed(unsigned char *pa);

/*Move to values array*/
unsigned int* values_array(unsigned char *pa);

/*Block size must be a multiple of 32*/
struct Scary* scary_create(unsigned int blocksize);

/*- In:
  Add new (unsigned int) into a linked list of compressed array, representing by
  head


        _ _ _ _ _
        |  len  | 
Head    _ _ _ _ | 
        | pre,pa| --> #(1 2 3 4 5 6 . . . )
        |  |    | 
	|_ |_ _ |
           |
           |
	   \/
        _ _ _ _ _
        |  len  | 
        _ _ _ _ | 
        | pre,pa| --> #(1 2 3 4 5 6 . . . )
        |  |    | 
	|_ |_ _ |
           |
           |
	   \/
           NIL

    Case a) if Head.pa still has space
                - insert the new arriving element
                - Check b)
         b) if Head.pa is full
	        - Compress Head.pa using PFORDELTA algorithm
                - Reclaim the unused space
		- Update Head.len = actual size used by Head.pa
		- Make a new Scary node newScarynode
		_ Update the new head 
		      newScaryNode.prev = Head
		      Head = newScaryNode
 
    Return Head
 - Out:
  Return a new head if compression was taken place 
  */
struct Scary* scary_insert(struct Scary* head, unsigned int element);
/*Get element at index. This operation will unpack the compressed array
 Options
 a) - should we KEEP the uncompressed array and DISCARD the compressed array ?
 b) - should we DISCARD the uncompressed array and KEEP the compressed array?

2013 - 09 -26 I go with option a
  
*/
int scary_get(struct Scary* head, unsigned int index);

/*Release all pointers, space occuppied by scary*/
void scary_release(struct Scary* head);

/*Print out the linked list of compressed array in the reversed order
  which they were inserted*/
void scary_print(struct Scary* head);
