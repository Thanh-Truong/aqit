/* serialize.c

linked list serialization example
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h> // string operations
#include <stdint.h> // fixed width integers

// just an example structure
typedef struct item { // I call this a list item, you can call it a node or an entry or 
                      // what ever you like :)
  uint8_t arrayLen; // this is an unsigned 8-bit integer
  char array[256];
  struct item *next;
} list;

void serializeList(list *item, char *buffer)
{
  int seeker = 0;  // integer to keep record of the wrinting position in 'buffer'
  while(item != 0) // copy contents of the linked list in buffer as long there 
  		   // are items in the list. In this example, loop is  
  		   // done three times.
  {

    memcpy(&buffer[seeker], &item->arrayLen, sizeof(item->arrayLen));
    seeker += sizeof(item->arrayLen); // move seeker ahead by a byte

    // copy characters from character array to the buffer
    memcpy(&buffer[seeker], &item->array, item->arrayLen);
    seeker += item->arrayLen; // ... and move the seeker ahead by the amount of	
    			      // characters in the array.

    item = item->next; // move on to the next item (or node) in the list
  }
}

int listSize(list *item)
{
  int size = 0;
  
  while (item != 0) {
    size += item->arrayLen; // add arrayLen bytes to 'size'
    size += sizeof(item->arrayLen); // add 4 bytes to 'size'
    item = item->next; // ... and to the batmobil!
  }
  return size;
}

int main (void)
{
  // have something to save the list start and end
  list *ptr; // pointer for traversing
  char *buffer; // this is where we serialize the list
  int listLength; // length of the list in bytes
  list first, second, third;
  ptr = &first; // ptr points to the first element of the list now
  
  FILE *filePtr; // this will point to the file we are using to verify the
  		 // results of this little experiment
  
  // creating a short linked list for this example
  strcpy(first.array, "apple");
  first.arrayLen = strlen(first.array);
  first.next = &second;
  					    
  strcpy(second.array, "gasoline");
  second.arrayLen = strlen(second.array);
  second.next = &third;
  
  strcpy(third.array, "jackass");
  third.arrayLen = strlen(third.array);
  third.next = 0;
  
  // listSize is a function returning length of the whole list in bytes
  listLength = listSize(ptr);
  
  // allocate memory for the list, and let 'buffer' point to it.
  buffer = (char *)malloc(listLength);
  
  // serializing list pointed by *ptr to char pointer named buffer
  serializeList(ptr, buffer);
  
  // For this example, we are writing 'buffer' into a file.
  // We could also send this buffer through a socket to another computer,
  // but that is out of the scope of this example
  filePtr = fopen("example.data", "wb+"); // a file called example.data will be
  					// created in the same folder as where
  					// this program resides upon execution.

  // writing 'buffer' of the size 'listLength' once (1) to file pointed by filePtr
  fwrite(buffer, listLength, 1, filePtr); // if I was smart, i'd be doing some error handling
  					  // here when trying to write to a file.
  					  
  // almost forgot... 
  fclose(filePtr); // close the file.
  free(buffer); // free memory reserved by the serialized list.
  
  return 0;
}
