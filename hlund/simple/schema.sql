/*------------------------------------------------------------------------
A - machine(m, mm) represents meta-data about each machine 
installation identified by m where mm identifies 
the machine model. 

There is a secondary B-tree index on mm.
B- sensor(m, s, sm, mc, ev, ad, rd): stores meta-data about 
each sensor installation.On each machine m each sensor of 
model sm is identified by a number s. 

To identify different kinds of measurements, e.g oil pressure, 
filter temperature etc., the sensors are classified by their 
measurement class, mc. Each sensor has absolute error deviation 
ad, and/or relative deviation rd from the expected value ev. 
There are secondary B-tree indexes on sk, ev, ad, and rd.

C- measuresMC (m, s, bt, et, mv): 
To enable efficient  analyses of the behavior of different 
measurement classes over many machine installations over time, 
the table measuresMC stores measurements mv of class MC for sensor 
installations identified by machine m and sensor s in time interval [bt,et). By storing bt and et temporal interval overlaps can be easily expressed in SQL [21][22]. There are secondary B-tree indexes on bt, et, and mv.
---------------------------------------------------------------------------
*/
use $(database)
go
/*Drop table machine*/
if exists (select 1 from sys.tables where name='machine' and  schema_id=1) 
           drop table machine

/*Drop table sensor*/
if exists (select 1 from sys.tables where name='sensor' and  schema_id=1) 
           drop table sensor

/*Drop table measuresA*/
if exists (select 1 from sys.tables where name='measuresA' and  schema_id=1) 
           drop table measuresA

go

/*Drop table measuresB*/
if exists (select 1 from sys.tables where name='measuresB' and  schema_id=1) 
           drop table measuresB

go
create table machine
(m   int,
 mm   nvarchar(20),
 primary key (m)
)
go

create table sensor
(m   int,
 s   int,
 sm  nvarchar(50),
 mc  nvarchar(20),
 ev  float,
 ad  float, /*Absolute deviation from ev*/
 rd  float, /*Relative deviation from ev*/ 
 primary key (m, s)
)
go 
create table measuresA
(m   int,
 s   int,
 bt  float,
 et  float,
 mv  float,
 primary key (m, s, bt)
)
go 
create table measuresB
(m   int,
 s   int,
 bt  float,
 et  float,
 mv  float,
 primary key (m, s, bt)
)
go 

/*----------------------------------------------------
 Implementation of GREATEST, supported in SQL:2003
----------------------------------------------------*/
if  exists (select 1 from sys.objects 
           where name ='greater' 
           and schema_id= 1)
     drop function [dbo].greater
go

create function greater(@expr1 float, @expr2 float)
returns float
as begin
   return case when @expr1 is null then NULL 
               when @expr2 is null then NULL
               when (@expr1 > @expr2) then @expr1
               else @expr2 end
end
go	
/*select top 1 dbo.greater(3.0,NULL) from sys.objects;
select top 1 dbo.greater(3.0,1.0) from sys.objects;
select top 1 dbo.greater(1.0,3.0) from sys.objects;
select top 1 dbo.greater(NULL,3.0) from sys.objects;
*/
/*----------------------------------------------------
 Implementation of LEASTEST, supported in SQL:2003
----------------------------------------------------*/

if  exists (select 1 from sys.objects 
           where name ='lesser' 
           and schema_id= 1)
     drop function [dbo].lesser
go

create function lesser(@expr1 float, @expr2 float)
returns float
as begin
   return case when @expr1 is null then Null
               when @expr2 is null then Null
               when (@expr1 > @expr2) then @expr2
               else @expr1 end
end
go
