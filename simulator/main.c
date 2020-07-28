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
#include "..\..\C\callin.h"
#include "..\..\C\callout.h"
#include "curve.h"
#include "gen.h"

void streamNumber(a_callcontext cxt, a_tuple t)
{
   double from, to;   
   from = a_getdoubleelem(t,0,FALSE);
   to = a_getdoubleelem(t,1,FALSE);  
   
}

void testIntRand()
{
  printf("Random num %d \n", sim_rand(1, 20));
  printf("Random num %d \n", sim_rand(1, 20));
  printf("Random num %d \n", sim_rand(1, 20));
  printf("Random num %d \n", sim_rand(1, 20));
  printf("Random num %d \n", sim_rand(1, 20));
  printf("Random num %d \n", sim_rand(1, 20));
  printf("Random num %d \n", sim_rand(1, 20));
  printf("Random num %d \n", sim_rand(1, 20));
  printf("Random num %d \n", sim_rand(1, 20));
  printf("Random num %d \n", sim_rand(1, 20));
  printf("Random num %d \n", sim_rand(1, 20));
  printf("Random num %d \n", sim_rand(1, 20));
}

void testDoubleRand()
{
  printf("Random dnum %f \n", sim_drand(1.0, 20.0));  
  printf("Random dnum %f \n", sim_drand(1.0, 20.0));
  printf("Random dnum %f \n", sim_drand(1.0, 20.0));  
  printf("Random dnum %f \n", sim_drand(1.0, 20.0));
  printf("Random dnum %f \n", sim_drand(1.0, 20.0));  
  printf("Random dnum %f \n", sim_drand(1.0, 20.0));
  printf("Random dnum %f \n", sim_drand(1.0, 20.0));  
  printf("Random dnum %f \n", sim_drand(1.0, 20.0));
  printf("Random dnum %f \n", sim_drand(1.0, 20.0));  
  printf("Random dnum %f \n", sim_drand(1.0, 20.0));
  printf("Random dnum %f \n", sim_drand(1.0, 20.0));  
  printf("Random dnum %f \n", sim_drand(1.0, 20.0));
  
}

void testUtilities() 
{
	testIntRand();
	testDoubleRand();
}


int main(int argc,char **argv)
{
	dcl_connection(c); 
	dcl_scan(s);
	// Read settings as environment variables
	read_CurveConfig();
	read_MachineConfig();

	// Initialize some variables
	init_time(&baseTime, 2001, 1, 1, 0, 0, 0);
	machine = 0;

	// Start program with a different seed for randomness
	srand(time(NULL)); 

	// Connect to embbeded database
	init_amos(argc,argv); 
	
	// Mapping foreign functions with their implementations
	a_extimpl("tstreambbf", tstreambbf); 
	a_extimpl("streamtofilebbf", streamtofilebbf);	
	a_connect(c,"",FALSE); 

	// Show the model
	//printf("All positive data and faulty is 0.05 percent \n");
	//a_execute(c, s,"plot_curve(1, 5000);",FALSE);

	free_scan(s);
	free_connection(c);

	amos_toploop("Amos2");  	
	return 0;
}









