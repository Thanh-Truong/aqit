SCARY : Streaming Comprresed Array
Modification to PForDelta original implementation to deal
with data stream since the original one does in batch


2013-09-26
- Reclaim the unused space after Pfordelta compression
  The old implementation did not reclaim the unused space.
  As stated in C Standard version 
  (C99, 7.20.3.4p2) "The realloc function deallocates the old 
  object pointed to by ptr and returns a pointer to a new object 
  that has the size specified by size."

  This is guaranteed that the remainder (not used) will be freed
