/*-*-sql-*-*******************************************************************
 * AMOS2
 *
 * Author: (c) 2012  Thanh Truong, UDBL
 * $RCSfile: queries.sql,v $
 * $Revision: 1.2 $ $Date: 2012/04/16 07:25:26 $
 * $State: Exp $ $Locker:  $
 *
 * Description: Queries database
 *
 ****************************************************************************
 * $Log: queries.sql,v $
 * Revision 1.2  2012/04/16 07:25:26  thatr500
 * changed datatypes
 * - machine integer,
 * - time    datetime,
 * - powcon  float
 *
 * Revision 1.1  2012/03/29 15:20:58  thatr500
 * seperate schema and queries
 *
 ****************************************************************************/

/*Q1---------------------------------------------------------------
Within the last 7 days, find machines (and times) whose power consumption 
are different from a thresold (500) not more than 10 unit.

It results in Index scan (full scan) over the entire IDX_LOG_PC
==> SLOW
----------------------------------------------------------------*/
sp_flushBuffer 1
select l.time, l.machine, l.powcon
from   logdata l 
where  abs(l.powcon - 500) < 10 and
       GETDATE() - l.time <= 7; 

/*Q2----------------------------------------------------------------
Each machine has its own expected power consumption.


Within the last 7 days, find machines (and times) whose power consumption 
has exceeded its expected thresold not more than 10 unit. 

It results in Index scan over the entire IDX_LOG_PC
==> SLOW
----------------------------------------------------------------*/
sp_flushBuffer 1
select l.time, l.machine, l.powcon
     from   logdata l, expdata e 
     where
	    abs(e.powcon - l.powcon) <= 10 and
            l.time >= getdate() - 30 and
            l.machine = e.machine and
            l.machine in (1, 2, 3);


/*Manually rewrite results in Index Seek on big table LogData.*/
/*Q1-rewritten ---------------------------------------------------------------
 It results in Index Seek on IDX_LOG_PC*/
select l.time, l.machine, l.powcon
from   logdata l 
where   
	l.powcon  > (500 - 10) and 
	l.powcon  < (500 + 10) and   
        l.time >= GetDate() - 7; 


/*Q2-rewritten ---------------------------------------------------------------
 It results in Index Seek on IDX_LOG_PC*/
select l.time, l.machine, l.powcon
from   expdata e ,logdata l 
where 
       l.powcon > e.powcon - 10 and
       l.powcon  < e.powcon + 10 and
       l.time >= GetDate() - 7 and
       l.machine = e.machine and
       l.machine in (1, 2, 3); 
		