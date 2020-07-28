#include<stdio.h>
#include<stdlib.h>
#include<limits.h>
#include<string.h>
#include "pfordelta.h"
#include "s16.h"
#include "coding_policy_helper.h"
#include "coding_policy.h"
#include "scary.h"
#include "storage.h"
#include "callin.h"
#include "callout.h"
int _block_size = 128;

EXPORT unsigned int DARRAY_TYPE;

/*Definition of Darray object in Amos*/
struct darraycell
{
  objtags tags;	
  unsigned int size;
  unsigned int csize;
  unsigned int base;
  unsigned int* pa;
};

EXPORT oidtype lisp_darray_makefn(bindtype env, oidtype osize);
EXPORT oidtype lisp_daray_getfn(bindtype env, oidtype darray, oidtype opos);
EXPORT oidtype lisp_darray_setfn(bindtype env, oidtype darray, oidtype opos, oidtype ovalue);
EXPORT oidtype lisp_darray_compressfn(bindtype env, oidtype darray);
EXPORT oidtype lisp_darray_decompressfn(bindtype env, oidtype darray);
EXPORT oidtype lisp_is_compressed_darrayfn(bindtype env, oidtype darray);


/*Free darray object called from garbage collector*/
void free_darrayfn(oidtype darray)
{  
  struct darraycell *da = dr(darray, darraycell);
  da->pa = NULL;
  //free(da->pa); /* Release an array pointed by pa */
  dealloc_object(darray); /* Deallocate the darray object itself */
}

/*Print out given instance darray on stream*/
void print_darrayfn(oidtype darray, oidtype stream, int princflg)
{
  struct darraycell *da;  
  da = dr(darray, darraycell);  
	
  a_puts("#[Delta-Array:",stream);
  a_puts(" size ", stream);
  a_puts(IntegerToString(da->size), stream);
  if (da->csize != -1) {
    a_puts(" 4-bytes. Compressed to ",stream);
    a_puts(IntegerToString(da->csize), stream);	
    a_puts(" 4-bytes",stream);
  } else {
    a_puts(" 4-bytes. Non-compressed ",stream);
  }
  a_putc(']',stream);		
}

//-----------------------------------------------------------------------------------
oidtype darray_make(unsigned int size) {
  struct darraycell *da;
  oidtype darray;
  unsigned int i;

  darray = new_object(sizeof(*da) + size * sizeof(unsigned int), DARRAY_TYPE);
  da = dr(darray, darraycell);
  da->size = size;
  da->pa = (unsigned int*)((&da->pa) + sizeof(unsigned int*));
  da->csize = -1;
  da->base = -1;
  for(i =0; i < size; i++){
    da->pa[i] = nil;
  }
  return darray;
}
//-----------------------------------------------------------------------------------
EXPORT oidtype lisp_darray_makefn(bindtype env, oidtype osize){
  oidtype darray;
  unsigned int size;

  IntoInteger(osize, size, env);
  darray = darray_make(size);
  return darray;
}
//-------------------------------------------------------------------
EXPORT oidtype lisp_darray_setfn(bindtype env, oidtype darray, oidtype opos, 
				 oidtype ovalue){
  unsigned int pos, refcount;
  struct darraycell *da;

  IntoInteger(opos, pos, env);
  da = dr(darray, darraycell);

  if (pos < da->size) {	
	refcount = (unsigned int) ref(doid(ovalue)); 
	a_setf(da->pa[pos], ovalue);
    /*printf("Set-val pa[%d]=%lu datatype %d can be reference counter %d ? \
			refcounter before %d now %d \n", pos, da->pa[pos], 
			a_datatype(da->pa[pos]),
			refcntp(doid(da->pa[pos])),
			refcount, (unsigned int)ref(doid(da->pa[pos])));*/
    return darray;
  }
  return nil;
}

//-------------------------------------------------------------------
EXPORT oidtype lisp_darray_getfn(bindtype env, oidtype darray, oidtype opos){	
  unsigned int pos;
  unsigned int value;
  struct darraycell *da;

  IntoInteger(opos, pos, env);
  da = dr(darray, darraycell);
  if (pos < da->size) { // unsigned int is always bigger than 0
    // The following line tries to assign value to the pointer pa
    // after loaded from data image, pa becomes invalid!!!
    da->pa = (unsigned int*)((&da->pa) + sizeof(unsigned int*));
    value = da->pa[pos];
    //return mkinteger(value);
    return value;
  }	
  return nil;
}
//-------------------------------------------------------------------
EXPORT oidtype lisp_darray_compressfn(bindtype env, oidtype darray){	
  unsigned int *coded;
  int size, newsize, i;
  oidtype newdarray;
  struct darraycell *da, *nda;

  da = dr(darray, darraycell);
  size = da->size;
  coded = (unsigned int *) malloc(size * sizeof(unsigned int) );
  da = dr(darray, darraycell);
  // Trick to reduce the numbers
  if (da->base == -1 && da->pa[0]!= nil) {
    da->base = da->pa[0];
    for(i=0; i < size; i++){
      da->pa[i] = da->pa[i] - da->base;
    }
  }
  
  newsize = compress_pfordelta(da->pa, coded, da->size, 32);

  // Make a new compressed darray
  newdarray = darray_make(newsize);
  nda = dr(newdarray, darraycell);
  da = dr(darray, darraycell);

  nda->size = da->size;
  nda->csize = newsize;
  nda->base = da->base;

  memcpy(nda->pa, coded, newsize * sizeof(unsigned int));
  
  //printf("From normal size: %d compressed to %d. So it saves %d \n",
  // da->size, newsize, da->size - newsize);
  free(coded);
  return newdarray;
}
//-------------------------------------------------------------------
EXPORT oidtype lisp_darray_decompressfn(bindtype env, oidtype darray){
  unsigned int *output;
  unsigned int size, finalsize, i;
  oidtype newdarray;
  struct darraycell *da,*nda;
  
  da = dr(darray, darraycell);
  size = da->size;
  output = (unsigned int *) malloc(size * sizeof(unsigned int) );
  da = dr(darray, darraycell);
  finalsize = decompress_pfordelta(da->pa, output, size, 32);
  // Since PDFDelta does not work correctly with big number
  // Simply by substracting the first element, the whole array elements become "small"
  // number
  if (da->base != -1) {
    for(i=0; i < size; i++){
      output[i] = output[i] + da->base;
    }
    da->base = -1;
  }
 
  // Make a new decompressed darray
  newdarray = darray_make(size);
  nda = dr(newdarray, darraycell);
  nda->size = size;
  nda->csize = -1;
  nda->base = -1;
  memcpy(nda->pa, output, size * sizeof(unsigned int));
  //printf("From compressed size: %d to normal size %d. So it wastes %d  \n",
  // da->csize, size, finalsize);

  free(output);
  return newdarray;
}
//-------------------------------------------------------------------
EXPORT oidtype lisp_is_compressed_darrayfn(bindtype env, oidtype darray){
  struct darraycell *da;
  da = dr(darray, darraycell);
  return (da->csize == -1)? nil: t;
  
}	
//-------------------------------------------------------------------
EXPORT void a_initialize_extension(void *xa)
{ 
  //Define foreign functions AmosQL
  extfunction1("darray-make", lisp_darray_makefn);
  extfunction2("darray-get", lisp_darray_getfn);
  extfunction3("darray-set", lisp_darray_setfn);
  extfunction1("darray-compress", lisp_darray_compressfn);
  extfunction1("darray-decompress", lisp_darray_decompressfn);
  extfunction1("darray-is-compressed", lisp_is_compressed_darrayfn);
  // Define a new Amos datatype: DARRAY
  DARRAY_TYPE =  a_definetype("DARRAY", free_darrayfn,
			      print_darrayfn);
  typefns[DARRAY_TYPE].deallocfn = free_darrayfn;
}
