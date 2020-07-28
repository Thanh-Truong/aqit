#include "scary.h"


/*Clear the 1st bit of the status*/
unsigned char get_slots(unsigned char *pa) {
   return *pa & ~((1<<7)); 
}

/*Return if the array is compressed or not*/
unsigned char is_compressed(unsigned char *pa) {
  return *pa & (1 << 7); 
}

/*Return if the array is compressed or not*/
void clear_compressed(unsigned char *pa) {
  *pa = *pa & ~(1 << 7); 
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

/*Preva is previous array of newa*/
void link_previous(unsigned char* newa, unsigned char* preva) {
  memcpy(newa + DESC_STATUS_SIZE, &preva, DESC_POINTER_SIZE);
}

/*Get previous array of pa and put it into preva*/
void get_previous(unsigned char* pa, unsigned char** preva) {
  memcpy(preva, pa + DESC_STATUS_SIZE, DESC_POINTER_SIZE);
}

/*======================================================================
  Public API 
 ========================================================================
*/
struct Scary* scary_create(unsigned int arraysize) {
  if ((arraysize % 32) == 0) {
     // Allocate head
    struct Scary* head;
    _scary_block_size_ = 32;  
    head= (struct Scary*) malloc(sizeof(*head));
    head->arraysize = arraysize;
    head->count = 1; 
    // Here pa is a pointer of unsigned char. It enables accessing
    // any byte gned char status = *(pa + DESC_STATUS_SIZE);
    allocate_array(head->pa, arraysize);
    return head;
  }
  return NULL;
}

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
	        -b.1 Compress Head.pa using PFORDELTA algorithm
                -b.2 Reclaim the unused space
		-b.3 Update Head.len = actual size used by Head.pa
		-b.4 Make a new Scary node newScarynode
		_b.5 Update the new head 
		      newScaryNode.id = head.id + 1;
		      newScaryNode.prev = Head
		      Head = newScaryNode
 
    Return Head
 - Out:
  Return a new head if compression was taken place 
  */
void compress_array(struct Scary *head, unsigned int arraysize){
  unsigned char *ca; // compressed array
  unsigned int newsize;
  printf("======compress======= ");
  allocate_array(ca, arraysize);

  // compress
  newsize = compress_pfordelta(values_array(head->pa), 
			       values_array(ca), 
			       arraysize, _scary_block_size_);
  // reallocate to shrinking the unused space
  ca = (unsigned char *) realloc(ca, newsize * sizeof(unsigned int) 
				 + DESC_STATUS_SIZE 
				 + DESC_POINTER_SIZE);
  // copy it status
  memcpy(ca, head->pa, DESC_STATUS_SIZE + DESC_POINTER_SIZE);

  printf("Status (slots %u , compressed %u)\n", get_slots(ca), is_compressed(ca));
  // free uncompressed array
  free(head->pa); 
  head->pa = ca;
  // update status
  set_compressed(ca);
}

struct Scary* scary_insert(struct Scary* head, unsigned int element)
{
  if (head != NULL) {
    unsigned char slots = get_slots(head->pa);
    unsigned int *vla = values_array(head->pa);
    unsigned int arraysize = head->arraysize;
    unsigned char *newa;

    if (slots < arraysize) {
      //printf("Before vla[%u]= %u ", slots, vla[slots]);
      vla[slots] = element;
      //printf("After vla[%u] = %u", slots, vla[slots]);
      if (slots == arraysize - 1) {
	// Pro-active compression + spawn
	// Array is full ( slot 127 --> 0)
	printf(" Array is full !!\n");
	// Compress array, head->pa points to a new compressed array
	compress_array(head, arraysize);
	// Spawn a new array
	allocate_array(newa, arraysize);
	// link them
	link_previous(newa, head->pa);
	head->pa = newa;
	head->count++;
      } else {
	increase_slots(head->pa);
      }
    }
  }
  return head;
}

/*Release all pointers, space occuppied by scary*/
void array_release(unsigned char*pa) {
  unsigned char**prev;
  prev = (unsigned char**) malloc(sizeof(unsigned char*));
  get_previous(pa, prev);

  free(pa);
  if (prev != NULL) {
    array_release(*prev);
  }
  free(prev);
}

void scary_release(struct Scary* head) {
  if (head != NULL) {
    unsigned char * pa = head->pa;
    free(head);
    if (pa != NULL) {
      array_release(pa);
    }
  }
}


/*Print out the linked list of compressed array*/
void array_print(unsigned char* pa, int headcount) {
  unsigned char **prev = malloc(sizeof(unsigned char*));
  printf("[Array #%d ", headcount);
  if (is_compressed(pa)) {
    printf(" Compressed");
  } else {
    printf(" Uncompressed");
  }
  printf(" used slots: %d] \n", get_slots(pa));
  
  get_previous(pa, prev);
  if (prev != NULL && *prev != NULL) {
      printf("    |\n");
      printf("    | \n");
      array_print(*prev, headcount - 1);
  }
  free(prev);
}

/*Print out the linked list of compressed array in the reversed order
  which they were inserted*/
void scary_print(struct Scary* head) {
  if (head != NULL && head->pa != NULL) {
    printf("|--------| \n");
    printf("| SCARY  | \n");
    printf("|--------| \n");
    printf("    |\n");
    printf("    | \n");
    array_print(head->pa, head->count);
  }
}
/*Get element at index. This operation will unpack the compressed array
  
 Options
 a) - should we KEEP the uncompressed array and DISCARD the compressed array ?
 b) - should we DISCARD the uncompressed array and KEEP the compressed array?

2013 - 09 -26 I go with option a
  
*/

void decompress_array(unsigned char *pa, unsigned char *output,
		      unsigned int arraysize) {
  unsigned int decompsize;
  memcpy(output, pa, DESC_STATUS_SIZE + DESC_POINTER_SIZE);
  printf("Decompressed \n");
  decompsize = decompress_pfordelta(values_array(pa), 
				    values_array(output), 
				    arraysize, 
				    _scary_block_size_);
  clear_compressed(output);
  //free(pa); // no longer needed
}
int scary_get(struct Scary* head, unsigned int index){
  unsigned int value = -1;
  if (head != NULL) {
    int arrayindex = index / head->arraysize;
    int remainder = index - (arrayindex * head->arraysize);
    unsigned char* pa = head->pa;
    // Pointer to array whose position == arrayindex
    unsigned char**prev = (unsigned char**) malloc(sizeof(unsigned char*));
    int prevpos = head->count - 2;// If there is 1 array, prevpos --> -1

    get_previous(pa, prev); // If there is 1 array, prev -->NULL
    while(prevpos > arrayindex && prev != NULL && *prev !=NULL){
      prevpos --;
      pa = *prev;
      get_previous(pa, prev);
    }
    // The top array is always uncompressed, just return value
    if (prevpos < arrayindex) {
      value = values_array(pa)[remainder];
    } else if (is_compressed(*prev)) {
      unsigned char *output;
      allocate_array(output, head->arraysize);
      decompress_array(*prev, output, head->arraysize);
      get_previous(pa, prev);
      free(*prev);
      link_previous(pa, output);
      get_previous(pa, prev);
      value = values_array(output)[remainder];
    } else {
      value = values_array(*prev)[remainder];
    }      
    free(prev);
  }    
  return value; 
}
