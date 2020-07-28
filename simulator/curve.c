/*****************************************************************************
 * AMOS2
 *
 * Author: (c) 2012 Thanh Truong, UDBL
 * $RCSfile: curve.c,v $
 * $Revision: 1.3 $ $Date: 2012/05/24 18:03:40 $
 * $State: Exp $ $Locker:  $
 *
 * Description: Generate a stream of (F(t), t) in which F(t) is adjustable
 * by parameters
 * ===========================================================================
 * $Log: curve.c,v $
 * Revision 1.3  2012/05/24 18:03:40  thatr500
 * Reading generator settings as environement variables
 *
 * Revision 1.2  2012/05/23 07:33:46  thatr500
 * More robust generator
 *
 * Revision 1.1  2012/05/21 07:19:21  thatr500
 * Generate a stream of (F(t), t)
 *
 *
 ****************************************************************************/

#include "curve.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
/*Calculate a trend of a peak at random*/
int calTrend() 
{
	int trend;
	if (SIM_POSITIVEVAL) 
	{
		trend = 1;
	} else 
	{
		trend = sim_rand(0,2);
		if (trend == 0) 
		{
			trend = -1;
		}		
	}
	return trend;
}

/*Calculate base*/
double calBase(double t)
{
	double base;
	base =  sim_drand(floor(SIM_HEIGHTN*0.5),  SIM_HEIGHTN)*sin(t);
	if (SIM_POSITIVEVAL && base < 0) 
	{
		base = 0;
	}  
	return base;	
}

/*In a peak area?*/
int inPeakArea(int c, int startp,int endp)
{
	return (c >= startp && c <= endp);
}

/*
0: stay
1: up
-1:down
*/
int direction(int c,int startp, int endp, int apeak) 
{
	int dir;
	if (inPeakArea(c, startp, endp))
	{
		if (c >= startp && c <= apeak) 
		{
			dir = 1;
		}
		if (c > apeak && c <= endp) 
		{
			dir = -1;
		}
	}
	return dir;
}

/*Peak in this iter should go beyond the thresold*/
int shouldbeyondThresold(int iter)
{
	return (SIM_PERCENT != 0 && iter % (int)floor(1/SIM_PERCENT)==0);
}
 

double compensate(double val, int iter)
{

	if (shouldbeyondThresold(iter))
	{
		if (val > 0 && val < SIM_THRESOLDU) 
		{
			val = SIM_THRESOLDU + sim_drand(0, SIM_HOWFAST +1); 
		} 
	} else
	{
		if (SIM_PERCENT !=0 && val > 0 && val > SIM_THRESOLDU)
		{
			 val = SIM_THRESOLDU - sim_drand(0, SIM_HOWFAST +1); 
		}
	}    
    return val;
}

/*Generate incremental number given its bound and step*/
oidtype tstreambbf(a_callcontext cxt)
{
	double t;
	int i;
	int startab;
	int endab;
	int trend;
	int apeak;
	double growth;
	double val;
	int numi;
	int iter;
	int numab;
	int c;	 
	double l, u;
	oidtype res;

	IntoDouble(a_arg(cxt,1),l,cxt->env); /* Unbox 1st arg */
	IntoDouble(a_arg(cxt,2),u,cxt->env); /* Unbox 2nd arg */
	a_let(res, nil);

	numi = (int)ceil((u - l) / (SIM_NUMC *SIM_LENGTHC)); /*# of iterations*/
	numab  = (int)floor(SIM_PERCENT*numi);    /*# of abnormality*/

	iter = 0;
	while(iter < numi)  /*Iteration*/
	{
		/*Re-calculate parameters of a peak happening at each iteration*/ 
		trend = calTrend();  
		startab = (int) sim_drand(floor(SIM_NUMC*1/2), SIM_NUMC*3/4);
        endab  =  (int) floor(SIM_NUMC*3/4);    
        apeak = sim_rand(startab, endab); 
        growth = SIM_HEIGHTA;
		
        c = 0;
        while (c < SIM_NUMC)   /*Cycle*/
		{
			i = 0;
			while (i < SIM_LENGTHC)  /* item*/
			{
				/* t = up to previous iteration */
				/* + current cycle data*/ 
				t = (iter * SIM_LENGTHC * SIM_NUMC) 
					+ c*SIM_LENGTHC + i + 1;      
				if (t > u) 
				{
					break;
				}

				/*continous data = F(t)*/
                val = calBase(t);               
                if (inPeakArea(c, startab, endab)) 
				{
					growth = growth + direction(c, startab, endab, apeak) * SIM_HOWFAST;
                    val = val + trend * growth; 
                    val = compensate(val,iter);                    
				}
                    
				/*Always positive ?*/
                if(SIM_POSITIVEVAL && val < 0 )
				{
					 val = 0;
				} 
				// Emit value				
				a_setf(res, new_array(2,nil));
				a_seta(res, 0, mkreal(val));
				a_seta(res, 1, mkreal(t));
				a_bind(cxt,3, res);
				a_result(cxt); /* Emit */
				a_free(res);
				i = i +1; /*Next item*/    
			}
			c = c + 1;    /*Next cycle*/  
		}
		iter = iter + 1; /*Next iteration*/
	}
	return nil;
} 

void read_CurveConfig()
{
	char *var;
	var = getenv ("SIM_NUMC");
	SIM_NUMC = (var!=NULL)?atoi(var):60;
	
	var = getenv ("SIM_HEIGHTN");
	SIM_HEIGHTN = (var!=NULL)?atoi(var):15;
	
	var = getenv ("SIM_LENGTHC");
	SIM_LENGTHC = (var!=NULL)?atoi(var):2;

	var = getenv ("SIM_HEIGHTA");
	SIM_HEIGHTA = (var!=NULL)?atoi(var):SIM_HEIGHTN;
	
	var = getenv ("SIM_HOWFAST");
	SIM_HOWFAST = (var!=NULL)?atof(var):2;
	
	var = getenv ("SIM_POSITIVEVAL");
	SIM_POSITIVEVAL = (var!=NULL)?atoi(var):0;
	
	var = getenv ("SIM_THRESOLDU");
	SIM_THRESOLDU = (var!=NULL)?atoi(var):(SIM_HEIGHTN*10);

	var = getenv ("SIM_PERCENT");
	SIM_PERCENT = (var!=NULL)?atof(var):0.05;
	
	var = getenv ("SIM_INTERVAL");
	SIM_INTERVAL = (var!=NULL)? atoi(var):5;

	/*printf("SIM_NUMC %f \n", SIM_NUMC );
	printf("SIM_HEIGHTN %f \n", SIM_HEIGHTN);
	printf("SIM_LENGTHC %d \n", SIM_LENGTHC);
	printf("SIM_HEIGHTA %f \n", SIM_HEIGHTA);
	printf("SIM_HOWFAST %f \n", SIM_HOWFAST);
	printf("SIM_POSITIVEVAL %f \n", SIM_POSITIVEVAL);
	printf("SIM_PERCENT %f \n", SIM_PERCENT);
	printf("SIM_THRESOLDU %f \n", SIM_THRESOLDU);
	printf("SIM_PERCENT %f \n", SIM_PERCENT);
	printf("SIM_INTERVAL %f \n", SIM_INTERVAL);*/
	
}
  
