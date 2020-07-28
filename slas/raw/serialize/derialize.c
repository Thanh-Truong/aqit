/* derialize.c, not deserialize. That's not a typo :)

WARRANTY: yeah right...
*/
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <sys/stat.h>

// this is the same structure we have in serialize.c
typedef struct item {
  uint8_t arrayLen; // using fixed width integers for portability
  char array[256];
  struct item *next;
} list;

// start and end of the linked list
list *start = 0;
list *end = 0;

// for this example, we are getting the filesize to find out how many
// bytes need to be read from example.data
int fileSize(char *filename) {
  struct stat buffer; //sys/stat
  char path[256]; // buffer for saving filename
  unsigned int size; // and this will hold the size returned by this function

  strcpy(path, "./"); // assuming that example.data is in the same folder
                      // this program
  strcat(path, filename); // append filename to after './'

  if(stat(path, &buffer) < 0) // get stat structure for example.data
    perror(path);
  else
    size = buffer.st_size; // st_size member of the stat structure holds
                           // the filesize
  return size;
}

// function to add 'item' to a linked list
void addToList(uint8_t arrayLen, char *buffer)
{
  list *ptr; // creating a pointer
  ptr = malloc(sizeof(ptr)); // allocate space for array and arrayLen
  
  if (start == 0) { // if this is the first element added to the list
    start = ptr; // structure pointed by ptr is first in the list
    ptr->next = 0; // next is 0, this is also the last item in the list
  }
  else { // if there are allready items in the list
    end->next = ptr; // last item in the list points to this.
  }
  end = ptr; // last item in the list is ptr
  ptr->next = 0; // this is the last item
  
  ptr->arrayLen = arrayLen; // put the values in the strucure
  strcpy(ptr->array, buffer);// same here
}

// simple function to traverse through a linked list and print contents
void printList (list *ptr)
{
  while(ptr != 0) {
    printf("arrayLen: %i, array: %s\n", ptr->arrayLen, ptr->array);
    ptr = ptr->next;
  }
}

int main (void)
{
  FILE *filePtr; // filepointer for opening a file
  int listLength = 0; // total length of the list in bytes
  int done = 0; // bytes added to linked list, used in looping through example.data
  uint8_t arrayLen; // 8-bit integer designating array length in bytes
  char *buffer; // buffer to st
  
  // determine total length of data (same as filesize in this example)
  listLength = fileSize("example.data");
  
  // open example.data we created with serialize
  filePtr = fopen("example.data", "rb"); // read binary
  
  // loop through the file until the whole file has been read
  while (done < listLength) {
    fread(&arrayLen, 1, 1, filePtr); // read first byte from file to arrayLen
                                     // first byte saved in the file was the length of 
                                     // 'apple' in bytes.
    buffer =(char *)malloc(arrayLen + 1); // allocate space for array and null character ('\0')
    fread(buffer, arrayLen, 1, filePtr); // read arrayLen amount of bytes from file
    buffer[arrayLen] = '\0'; // add ending character to character array
    addToList(arrayLen, buffer); // adding arrayLen and array(located in buffer) to linked list
    done += arrayLen + 1; // done is length of array plus one byte for arrayLen
    free(buffer);
  }
  
  // print linked list to confirm result
  printList(start);
  
  return 0;
}
