#include "slwinstats.h"

extern unsigned int SLWINSTATS_TYPE;

/*Make a new instance of SL WinStat storage type*/
oidtype make_winstats0fn(bindtype env){
  struct SLWinStatsCell *dx;
  oidtype wstats;

  wstats = new_object(sizeof(*dx), SLWINSTATS_TYPE);
  dx = dr(wstats, SLWinStatsCell);	
  dx->count = 0;
  dx->avg = 0.0;
  dx->min = 0.0;
  dx->max = 0.0;
  dx->stdev = 0.0;
  
  return wstats;
}
/*Make a new instance of SL WinStat storage type*/
oidtype make_winstatsfn(bindtype env, oidtype start){
  struct SLWinStatsCell *dx;
  int nstart;
  oidtype wstats = make_winstats0fn(env);
  dx = dr(wstats, SLWinStatsCell);
  IntoInteger(start, nstart, env);
  dx->startTime = nstart;
  return wstats;
}

/*Deallocate given instance of SL WinStat storage type*/
void free_winstatsfn(oidtype winstats) {
  struct SLWinStatsCell *dx = dr(winstats, SLWinStatsCell);
  dealloc_object(winstats); /* Deallocate the wstats object itself */
}

/*Print out given instance mexi on stream*/
void print_winstatsfn(oidtype winstats, oidtype stream, int princflg) {
  if (stdoutstream == stream || stderrstream == stream) {
    struct SLWinStatsCell *dx;
    double dv;
    dx = dr(winstats, SLWinStatsCell);	
    a_puts("#[SLWINSTATS ", stream);
    a_puti(sizeof(struct SLWinStatsCell), stream);
    a_putc(']', stream);
    a_putc(' ', stream);
    a_puts("startTime ", stream);
    a_puti(dx->startTime, stream);
    a_putc(' ', stream);
    a_puts("count ", stream);
    a_puti(dx->count, stream);
    a_putc(' ', stream);
    return;
  } else {
     struct  SLWinStatsCell *dx = dr(winstats, SLWinStatsCell);
     /* Content bytes */
     char *buff=(char *)dx;
     int size = sizeof(struct SLWinStatsCell);
     a_puts("#[WSTATS ",stream);
     a_puti(size,stream);
     a_puts("] ",stream);
     a_writebytes(stream,(void *)buff,size);
     a_putc(' ',stream); /* delimiter */
  }
}

oidtype read_winstatsfn(bindtype env, oidtype tag, oidtype x,
			  oidtype stream) {
  int bytes;
  oidtype res;
  oidtype size = hd(x);
  struct SLWinStatsCell *dres;
  char *buff;
  objtags tags;

  IntoInteger(size, bytes, env); /* Total size in bytes */

  res = new_aligned_object(bytes, SLWINSTATS_TYPE);
  dres = dr(res, SLWinStatsCell);
  tags = dres->tags;
  buff = (char *)dres;
  a_getc(stream); /* Skip space after ] */
  a_readbytes(stream, buff, bytes);
  a_getc(stream);
  dres->tags = tags; /* restore initialized tags */
  return res;
}

/*Register a derrived storage type*/
int  register_winstats(){
  SLWINSTATS_TYPE = a_definetype("SLWINSTATS", free_winstatsfn, NULL);
  /*In case it exists a storagetype with the same name. It is better to wire up
    deallocation and print function as the following*/
  typefns[SLWINSTATS_TYPE].deallocfn = free_winstatsfn;
  typefns[SLWINSTATS_TYPE].printfn = print_winstatsfn;
  type_reader_function("SLWINSTATS", read_winstatsfn);
 type_reader_function("WSTATS", read_winstatsfn);
  return SLWINSTATS_TYPE;
}
/*--------------------------API-----------------------------------*/
/*Set stat value v*/
oidtype winstats_set_statfn(bindtype env, oidtype wstats, oidtype stat, 
			    oidtype v){
  struct SLWinStatsCell *dx;
  char *strstat;
  double dv;
  int    iv;
  dx = dr(wstats, SLWinStatsCell);	
  IntoString(stat, strstat, env);
  IntoDouble(v, dv, env);
  //a_print(v);
  //printf("winstats_set_statfn %f \n", dv);
  if (strcmp(strstat, "AVG") == 0) {
    dx->avg = dv;
  } if (strcmp(strstat, "STDEV") == 0) {
    dx->stdev = dv;
  } if (strcmp(strstat, "MIN") == 0) {
    dx->min = dv;
  } if (strcmp(strstat, "MAX") == 0) {
    dx->max = dv;
  } if (strcmp(strstat, "COUNT") == 0) {
    dx->count = dv;
  } if (strcmp(strstat, "START") == 0) {
    IntoDouble(v, iv, env);
    dx->startTime = iv;
  }
  return wstats;
}
/*Get stat*/
oidtype winstats_get_statfn(bindtype env, oidtype wstats, oidtype stat){
  struct SLWinStatsCell *dx;
  char *strstat;
  double dv;
  dx = dr(wstats, SLWinStatsCell);	
  IntoString(stat, strstat, env);
  if (strcmp(strstat, "AVG") == 0) {
    dv = dx->avg;
  } if (strcmp(strstat, "STDEV") == 0) {
    dv = dx->stdev;
  } if (strcmp(strstat, "MIN") == 0) {
    dv = dx->min;
  } if (strcmp(strstat, "MAX") == 0) {
    dv = dx->max;
  } if (strcmp(strstat, "COUNT") == 0) {
    dv = dx->count;
  } 
  return mkreal(dv);
}

/*Startx window*/
oidtype winstats_startfn(bindtype env, oidtype wstats) {
  struct SLWinStatsCell *dx;
  dx = dr(wstats, SLWinStatsCell);
  return mkinteger(dx->startTime);
}

/*Stop window*/
oidtype winstats_stopfn(bindtype env, oidtype wstats) { 
  return nil;
}

/*Offset window*/
oidtype winstats_offsetfn(bindtype env, oidtype wstats){
  struct SLWinStatsCell *dx;
  dx = dr(wstats, SLWinStatsCell);	
  return mkinteger(dx->byte_offset);
}

/*Byte size window*/
oidtype winstats_byte_sizefn(bindtype env, oidtype wstats) {
  struct SLWinStatsCell *dx;
  dx = dr(wstats, SLWinStatsCell);	
  return mkinteger(dx->byte_size);
}

/*Register window statistic function*/
void register_winstatsfn() {
  // Two version of make
  extfunction1("winstats-make", make_winstatsfn);

  // General setter & getter given attribute name
  extfunction3("winstats-set-stat", winstats_set_statfn);
  extfunction2("winstats-get-stat", winstats_get_statfn);

  // Some getters. Others are defined in LISP to use general
  // setters & getters
  extfunction1("winstats-start", winstats_startfn);
  extfunction1("winstats-stop", winstats_stopfn);
  extfunction1("winstats-offset", winstats_offsetfn);
  extfunction1("winstats-byte-size", winstats_byte_sizefn);
}
