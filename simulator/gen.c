/*****************************************************************************
 * AMOS2
 *
 * Author: (c) 2012 Thanh Truong, UDBL
 * $RCSfile: gen.c,v $
 * $Revision: 1.3 $ $Date: 2012/05/24 18:03:40 $
 * $State: Exp $ $Locker:  $
 *
 * Description: Stream (ManchineId, Time, PowCon) into a comma separate file.
 * ===========================================================================
 * $Log: gen.c,v $
 * Revision 1.3  2012/05/24 18:03:40  thatr500
 * Reading generator settings as environement variables
 *
 * Revision 1.2  2012/05/23 07:33:46  thatr500
 * More robust generator
 *
 * Revision 1.1  2012/05/21 07:20:22  thatr500
 * stream (ManchineId, Time, PowCon) into a comma separate file.
 *
 *
 ****************************************************************************/

#include "gen.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

/*Rotate machine id from 1 to MAX_MACHINE*/
int rotateMachine() 
{
	int val = ++machine;
	if (machine == MAX_MACHINE)
	{
		machine = 0;
	} 
	return val;
}
/*-----------------------------------------------------
Get time of day
-------------------------------------------------------
*/
void gettimevalofday(struct timeval* res)
{
#ifdef UNIX
  struct timezone tzp; /* Not used */
  gettimeofday(res, &tzp);
#else
  struct timeb tm;
  ftime(&tm);  
  res->tv_sec=tm.time;
  res->tv_usec=1000*tm.millitm;
#endif
}
/*-----------------------------------------------------
Add in a second d to rt
-------------------------------------------------------
*/
void add_duration(struct timeval* rt, double d) {
  unsigned long sec  = (unsigned long)floor(d);
  unsigned long usec = (unsigned long)a_round((d-sec)*1000000.);
  if((rt->tv_usec += usec) >= 1000000) {
    rt->tv_usec -= 1000000;
    rt->tv_sec += sec +1;
  } else {
    rt->tv_sec += sec;
  }
}

void init_time(struct timeval* res, int year, int month, int day, int hour, int minute, int second)
{
	time_t rawtime;
	struct tm * timeinfo;  
  
	/* get current timeinfo and modify it to the user's choice */
	time (&rawtime);
	timeinfo = localtime ( &rawtime );
	timeinfo->tm_year = year - 1900;
	timeinfo->tm_mon = month - 1;
	timeinfo->tm_mday = day;
	timeinfo->tm_hour = hour;
	timeinfo->tm_min = minute;
	timeinfo->tm_sec = second;
	
	/* call mktime: timeinfo->tm_wday will be set */
	rawtime = mktime ( timeinfo );
	res->tv_sec = rawtime;
	res->tv_usec = 0;
}
/*-----------------------------------------------------
Timeval to string
-------------------------------------------------------
*/
char *timetostring(struct timeval t)
{
   struct tm *date;
   static char str[40];

   date = localtime(&t.tv_sec);
   sprintf(str,"%d-%02d-%02d %02d:%02d:%02d.%003d",date->tm_year+1900,
           date->tm_mon+1, date->tm_mday, date->tm_hour, date->tm_min,
           date->tm_sec, t.tv_usec/1000);
   return str;
}

/*----------------------------------------------------
Write a line: MachineID,Time,PowCon
------------------------------------------------------*/
void writeline(FILE *file, int machineId, struct timeval time, double powcon) 
{
	fprintf(file, "%d,%s,%f\n", machineId, timetostring(time), powcon);	
}


oidtype writetupleMapper(a_callcontext cxt, int width, oidtype res[],void *xa)
{ 
  oidtype ov;
  int size, i;
  struct timeval time;
  double *tuple;  

  // Pick vector of (F(t), t)
  ov = res[0];
  if (arrayp(ov)) 
  {
		size = dr(ov, arraycell)->size;  
		tuple = (double *) malloc(sizeof(double) * size);
		for (i = 0; i < size ; i ++) {
			tuple[i] = getreal(dr(ov, arraycell)->cont[i]);    
		}
	   /*Add duration to base time*/
	    time = baseTime;
        add_duration(&time, tuple[1]*5);
		/*Write it*/
		writeline(f, rotateMachine(), time, tuple[0]);
		free(tuple);
  }	
  return nil;
}

oidtype streamtofilebbf(a_callcontext cxt)
{
	oidtype ofname;
	oidtype b;
	char *strfname;

	{unwind_protect_begin;	
	    //Unbox filename and open file
		ofname = a_arg(cxt, 1);
     	IntoString(ofname, strfname, cxt->env);
		f = fopen(strfname, "a");

		//Unbox a bag and map over it
		b = a_arg(cxt, 2);
		a_mapbag(cxt, b, writetupleMapper, NULL);

	unwind_protect_catch; 
		fclose(f);
	unwind_protect_end;	
	}
	return nil;
}


void read_MachineConfig()
{
	char *var;
	var = getenv ("MAX_MACHINE");
	MAX_MACHINE = (var!=NULL)?atoi(var):100;
	
} 