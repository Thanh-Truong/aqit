/*****************************************************************************
 * AMOS2
 *
 * Author: (c) 2012 Thanh Truong, UDBL
 * $RCSfile: curve.h,v $
 * $Revision: 1.2 $ $Date: 2012/05/24 18:03:40 $
 * $State: Exp $ $Locker:  $
 *
 * Description: Header of stream generator (F(t), t)
 * by parameters
 * ===========================================================================
 * $Log: curve.h,v $
 * Revision 1.2  2012/05/24 18:03:40  thatr500
 * Reading generator settings as environement variables
 *
 * Revision 1.1  2012/05/21 07:19:22  thatr500
 * Generate a stream of (F(t), t)
 *
 *
 ****************************************************************************/

#ifndef _curve_h_
#define _curve_h_

#include "..\..\C\callin.h"
#include "..\..\C\callout.h"
#include <time.h>
#include <sys/types.h>
#include <sys/timeb.h>
#include <windows.h>

#define sim_rand(a,b)  ((a!=b)?((rand()%(b-a) + a)):a)
#define sim_drand(a,b) (a + ((double)rand() / RAND_MAX)*(b-a))

/*Number of cycles in an iteration*/
double SIM_NUMC;

/*height of inactive curve, max value of non intersting value*/
double SIM_HEIGHTN;

/*length of a cycle 1s*/
int SIM_LENGTHC;

/*Base for height of abnormal curve, max value of active data
SIM_HEIGHTA=SIM_HEIGHTN, be carefully !!!!*/
double SIM_HEIGHTA;

/*How fast  a peak grows*/
double SIM_HOWFAST;

double SIM_POSITIVEVAL;

/*Thresold Up = SIM_THRESOLDU=SIM_HEIGHTN*10;*/
double SIM_THRESOLDU;

/*How many % of total data, abnormality happens*/
double SIM_PERCENT;

/*How many seconds a report is sent / data generated after this interval (in 
seconds)*/
double SIM_INTERVAL;

/*Functions in AMOSQL*/
void read_CurveConfig();
oidtype tstreambbf(a_callcontext cxt);
#endif
