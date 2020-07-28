/*
delete from hagglund_4GB.dbo.measuredValueREG407

insert into hagglund_4GB.dbo.measuredValueREG407 (e, ts, mv) 
select s.e,s.ts, s.mv from hagglund_2GB.dbo.measuredValueREG407 s
*/
use E01PS10_2991

/*Table measuredValueReg407
  - Total rows: 5169000
  - How many rows under 10.0 ?
    3195703
  - A cycle: ts < 1313681285
      
  
  */

select count(*) from (select ts, mv from measuredValueREG407
where e = 1 and mv > 0.0 and mv < 10.0) as temp
/*5169000*/
  
select ts, mv from measuredValueREG407
where e = 1 and mv > 0.0 and mv < 10.0

/*Seem to be a cycle*/
select ts, mv from measuredValueREG407
where e = 1 and ts < 1313681285

select count(*) from measuredValueREG407
where e = 1 and ts < 1313681285

select count(*) from measuredValueREG407
where e = 1 and ts < 1313681285 and mv < 15.0


drop table sampleReg407;

create table sampleReg407
(e int, ts float, mv float);

insert into samplereg407 (e, ts, mv) 
 select m.e, m.ts, m.mv from measuredValueREG407 m where
 e = 1 and ts < 1313681285;

create index idx_samplereg407_mv on samplereg407 (mv);

/*---------------------------------------------
 From now on, we work on table sampleReg407
-----------------------------------------------*/
select COUNT(*) from sampleReg407;
/*21711*/

select count(*) from sampleReg407 where
mv -15.6 > 344.4;

select count(*) from sampleReg407 where
mv -15.6 > 338.75;

select count(*) from sampleReg407 where
mv -15.6 > 281.4;

select count(*) from sampleReg407 where
mv - 15.6 > 130.4;


select count(*) from sampleReg407 where
mv -15.6 > 95.3;

select count(*) from sampleReg407 where
mv -15.6 > 72.72;

select count(*) from sampleReg407 where
mv -15.6 > 38.65;


select count(*) from sampleReg407 where
mv > 17.039
16441

select count(*) from sampleReg407 where
mv > 17.04


select count(*) from sampleReg407 where
mv > 17.02

DBCC SHOW_STATISTICS ('samplereg407 ', idx_samplereg407_mv) 
WITH HISTOGRAM

/*---------------------------------------------
 From now on, we work on table sampleReg408
-----------------------------------------------*/
use E01PB30_3190
/*Table measuredValueReg408
  A) Move data to sampleReg408      
  
  */

create table sampleReg408
(e int, ts float, mv float);

insert into sampleReg408 (e,ts,mv) select s.e, s.ts, s.mv
 from measuredValueREG408 s;

select COUNT(*) from measuredValueREG408
where e = 1;
/*1552000*/
/*0*/
select COUNT(*) from measuredValueREG408
where mv >   20 + 20 or mv < 20 - 20

/*1%*/
select COUNT(*) from measuredValueREG408
where mv >   20 + 10.92 or mv < 20 - 10.92

/*5%*/
select COUNT(*) from measuredValueREG408
where mv >   20 + 4.028 or mv < 20 - 4.028

/*10%*/
select COUNT(*) from measuredValueREG408
where mv >   20 + 2.495 or mv < 20 - 2.495

/*15%*/
select COUNT(*) from measuredValueREG408
where mv >   20 + 1.84 or mv < 20 - 1.84

/*20%*/
select COUNT(*) from measuredValueREG408
where mv >   20 + 1.5 or mv < 20 - 1.5

/*25%*/
select COUNT(*) from measuredValueREG408
where mv >   20 + 1.29 or mv < 20 - 1.29
/*30%*/
select COUNT(*) from measuredValueREG408
where mv >   20 + 1.05 or mv < 20 - 1.05

/*45%*/
select COUNT(*) from measuredValueREG408
where mv >   20 + 0.7 or mv < 20 - 0.7
/*50%*/
select COUNT(*) from measuredValueREG408
where mv >   20 + 0.6 or mv < 20 - 0.6
/*75%*/
select COUNT(*) from measuredValueREG408
where mv >   20 + 0.35 or mv < 20 - 0.35

/*100%*/
select COUNT(*) from measuredValueREG408
where mv >   20 or mv < 20


DBCC SHOW_STATISTICS ('measuredValueREG408', idx_measuredValueReg408_v) 
WITH HISTOGRAM
use hagglund_2
exec sp_spaceused measuredValueREg408