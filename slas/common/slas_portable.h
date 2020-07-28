#ifndef _SLAS_PORTABLE_
#define _SLAS_PORTABLE_

// Windows
#if defined(_WIN32) || defined(_WIN64)
	#if _MSC_VER == 1200 // VC++ 6.0
	        #define spos_t long
                #define sftell(stream) ftell(stream) 
                #define sfseek(stream, offset, origin)  fseek(stream, offset, origin)
	#endif
	#if _MSC_VER > 1200  // from VC++ 7.0 above
		#define spos_t __int64
	
		#ifndef _FSEEKI64_VC 
			#define  _FSEEKI64_VC
			extern "C" int __cdecl _fseeki64(FILE *, __int64, int)
			extern "C" __int64 __cdecl _ftelli64(FILE *)
		#endif

        #define sftell(stream) _ftelli64(stream)
        #define sfseek(stream, offset, origin)  _fseeki64(stream, offset, origin)
	#endif
#endif

// Unix or Linux
#if defined(__unix_) || defined(__linux__)
	#if _INTEGRAL_MAX_BITS >= 64 // 64 bit machine
		#define _FILE_OFFSET_BITS 64 // this will turn off_t into 64-bit type
        #endif

	#define spos_t off_t
        #define sftell(stream) ftello(stream) 
        #define sfseek(stream, offset, origin)  fseeko(stream, offset, origin)
#endif

// Mac OSX
#ifdef __APPLE__
    #if _INTEGRAL_MAX_BITS >= 64 // 64 bit machine                          
          #define _FILE_OFFSET_BITS 64 // this will turn off_t into 64-bit type 
    #endif                                                                      
                                                                                
    #define spos_t off_t                                                    
    #define sftell(stream) ftello(stream)                                     
    #define sfseek(stream, offset, origin)  fseeko(stream, offset, origin) 
#endif


#endif

/*Problem with fseek on opened text stream

  Read this http://msdn.microsoft.com/en-us/library/75yw9bf3.aspx
*/
