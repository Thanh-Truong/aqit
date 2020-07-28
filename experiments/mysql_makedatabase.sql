/*-*-sql-*-*******************************************************************
 * AMOS2
 *
 * Author: (c) 2012 Thanh Truong, UDBL
 * $RCSfile: mysql_makedatabase.sql,v $
 * $Revision: 1.2 $ $Date: 2012/04/16 07:22:38 $
 * $State: Exp $ $Locker:  $
 *
 * Description: Make database in MySQL
 *
 ****************************************************************************
 * $Log: mysql_makedatabase.sql,v $
 * Revision 1.2  2012/04/16 07:22:38  thatr500
 * changed datatypes
 * - machine integer,
 * - time    datetime,
 * - powcon  float
 *
 * Revision 1.1  2012/03/22 08:39:01  thatr500
 * *** empty log message ***
 *
 * Revision 1.1  2012/03/22 08:29:03  thatr500
 * *** empty log message ***
 *
 *
 ****************************************************************************/

drop table if exists expdata;
drop table if exists logdata;

/*Suppose there are 10 running machines. Each machine has an unique machine id.
  Moreover, it also is attached with a power comsumption counter which measures 
  how much power it cosumes.

 Expdata stores sampling data from these machines.  */
create table expdata (
    machine         integer not null,
    powcon          float not null ,
    primary key(machine)
);

create table logdata (
    time            datetime not null,
    machine         integer not null,
    powcon          float not null     
);

create index logdata_powcon_index using btree on logdata (powcon);

describe expdata;
describe logdata;
show index from logdata;



