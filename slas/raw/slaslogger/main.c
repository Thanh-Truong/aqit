/*****************************************************************************
 * AMOS2
 * 
 * Author: (c) 2012 Thanh Truong, UDBL
 * $RCSfile: main.c,v $
 * $Revision: 1.3 $ $Date: 2012/05/24 18:04:14 $
 * $State: Exp $ $Locker:  $
 *
 * Description: Simulator main
 ****************************************************************************/
#include "../../../C/callin.h"
#include "../../../C/callout.h"
#include "../../../C/scsq.h"
#include "slaslogger.h"
#include "read_blogfile.h"
#include "write_blogfile.h"
#include <stdio.h>
#include <stdlib.h>

#if defined(_WIN32) || defined(_WIN64)
#include <windows.h>
#else
#include <unistd.h>
#include <termios.h>
#include <sys/time.h>
#endif
#include <signal.h>


extern void testGenerate();
extern void testGetRandom();
extern void testMap();
extern void testRelease();

extern unsigned int SWINTYPE;
extern unsigned int SLWINSTATS_TYPE;

extern oidtype readblogfilebbf(a_callcontext cxt); 
extern oidtype slas_write_indexed_logfilebbf(a_callcontext cxt);
extern oidtype write_window_blogfilebbf(a_callcontext cxt);
extern oidtype write_window_blogfile1bbf(a_callcontext cxt);
extern oidtype readblogfilebbf(a_callcontext cxt);

extern int register_swincell();
extern void register_swinfns();
extern int init_scsq(int argc, char **argv);

static oidtype realtime_form;
 
void defineForeignFunction(){
  amosql("create function slaslogger1(Bag of Vector b, Number indexedpos, Charstring logfilename)-> \
          Boolean \
          as  foreign 'slas_write_indexed_logfilebbf';",FALSE);
  amosql("create function readblogfile(Charstring logfilename, Number cols)-> Bag of Vector \
          as  foreign 'readblogfilebbf';", FALSE);
}


void execute_when_timer_elapsed() {
     // Evaluate form without holding the result
     evalfn(varstack, realtime_form);
}

/*Realtime timer which executes fn (ALisp) every period of second(s). 
  Note that, fn should not be evaluated by aLisp interpreter when this C
  set_realtime_timerfn function is called. 
  See aStorage.pdf : Defining special forms
  References:
  - http://www.gnu.org/software/libc/manual/html_node/Setting-an-Alarm.html
  - http://users.csc.calpoly.edu/~gfisher/classes/357/lectures/8.html

Note:

   exfunctionq is to map a variable arity function and all arguments are not evaluated.
   That is to have the form unevaluated. Other arguments, I have to evaluate manually. 
*/
oidtype slas_set_timerfn(bindtype args, bindtype env) {
#if defined(_WIN32) || defined(_WIN64)
  return nil;
#else
  oidtype  which = nil, period = nil, ewhich = nil, eperiod = nil;
  int arity = envarity(args), int_which, signal;
  double periodsecs;

  struct itimerval tbuf;               // interval timer structure 
  struct sigaction action;             // signal action structure

  if (arity == 3) {
     a_setf(realtime_form, nthargval(args,1));
     a_setf(period, nthargval(args,2));
     a_setf(which, nthargval(args,3));
     //Evaluate period and which
     a_setf(eperiod, evalfn(env, period));
     a_setf(ewhich, evalfn(env, which));
     //Get double values
     IntoDouble(eperiod, periodsecs, env);
     IntoDouble(ewhich, int_which, env);

     //Use the setitimer function to start the timer.
     if (int_which == 1) {
        int_which = ITIMER_REAL; 
        signal = SIGALRM;
     } else if (int_which == 2) {
        int_which = ITIMER_VIRTUAL;
        signal = SIGVTALRM;   
     } else if (int_which == 3) {
        int_which = ITIMER_PROF;
        signal = SIGPROF;
     } else {
        int_which = -1; // Error should happen   
        signal = -1;
     }

     //Set up the Signal handler handler.
     action.sa_handler = execute_when_timer_elapsed; // set execute_when_timer_elapsed
     sigemptyset(&action.sa_mask); // clear out masked functions 
     action.sa_flags   = 0;        // no special handling
     
     //Use the sigaction function to associate the signal action with SIGALRM.
     if (sigaction(signal, &action, NULL) < 0 ) {
       perror("SIGALRM");
       exit(-1);
     }
     // Define a periodsecs timer.
     // This is the period between successive timer interrupts. 
     // If zero, the timer will only be sent once. 
     tbuf.it_interval.tv_sec  = (unsigned long) floor(periodsecs);
     tbuf.it_interval.tv_usec = (unsigned long) a_round((periodsecs - tbuf.it_interval.tv_sec)*1000000.);
     // This is the period between now and the first timer interrupt. If zero, the timer is disabled.
     tbuf.it_value.tv_sec  = (unsigned long) floor(periodsecs);
     tbuf.it_value.tv_usec = (unsigned long) a_round((periodsecs - tbuf.it_interval.tv_sec)*1000000.);

  
     if (setitimer(ITIMER_REAL, &tbuf, NULL) == -1 ) {
       perror("setitimer");
       exit(-1);                   // should only fail for serious reasons
     }
     // Release form & period
     a_free(period);
     a_free(eperiod);
     a_free(which);
     a_free(ewhich);
  }
  if (realtime_form == nil) {
     a_free(realtime_form);
  }
#endif
  return nil;
}
 
int main(int argc,char **argv){
  int rc;
  dcl_connection(c); 
  dcl_scan(s);

  // Start program with a different seed for randomness
  srand(time(NULL)); 

  // Connect to embbeded database
  //init_amos(argc,argv);
  //a_default_image = "slaslogger.dmp";
  rc = init_scsq(argc,argv);
	
  SWINTYPE = register_swincell();
  register_swinfns();
  SLWINSTATS_TYPE = register_winstats();
  register_winstatsfn();
  // Mapping foreign functions with their implementations
  a_extimpl("readblogfilebbf", readblogfilebbf);
  a_extimpl("slas_write_indexed_logfilebbf", slas_write_indexed_logfilebbf);
  a_extimpl("write_window_blogfilebbf", write_window_blogfilebbf);
  a_extimpl("write_window_blogfile1bbf", write_window_blogfile1bbf);
  a_extimpl("xxxbbf", xxxbbf);
  // Real-time timer  
  realtime_form = nil;
  extfunctionq("slas-set-timer", slas_set_timerfn);

  a_connect(c,"",FALSE); 

  free_scan(s);
  free_connection(c);

  // Define foreign function - 2013-09-24 Loaded from script init.osql
  // defineForeignFunction();

  // Testing
  //testGenerate();
  //testGetRandom();
  //testMap();
  //testRelease(),
  if(rc) return rc;
  amos_toploop("SlasRaw");  	
  return 0;
}









