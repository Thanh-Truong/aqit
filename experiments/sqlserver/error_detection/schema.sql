/*-*-sql-*-*******************************************************************
 * AMOS2
 *
 * Author: (c) 2012  Thanh Truong, UDBL
 * $RCSfile: schema.sql,v $
 * $Revision: 1.4 $ $Date: 2012/06/18 11:35:16 $
 * $State: Exp $ $Locker:  $
 *
 * Description: Schema database
 *
 ****************************************************************************
 * $Log: schema.sql,v $
 * Revision 1.4  2012/06/18 11:35:16  thatr500
 * removed codes
 *
 * Revision 1.3  2012/05/23 15:58:38  thatr500
 * re-organized columns
 *
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
          
/*------------------------------------------------
 SCHEMA
-------------------------------------------------*/
/*Choose database*/
use $(database)
go
/*Drop table logdata*/
if exists (select 1 from sys.tables where name='logData' and  schema_id=1) 
           drop table logData
go
/*Drop table expdata*/
if exists (select 1 from sys.tables where name='expdata' and  schema_id=1) 
           drop table expdata

go
/*Create table logdata*/
create table logData
(time datetime not null,
 machine integer not null,
 powcon float NOT NULL) 
go 
 /*Create table expdata*/
 create table expData
(machine integer not null,
 powcon float NOT NULL) 
 
go
/*Physical index B-tree on Powercon*/
if  exists (select * from sys.indexes where name = 'idx_log_pc')
drop index idx_log_pc on Logdata
go
create clustered index IDX_LOG_PC on LogData(powcon)

if  exists (select * from sys.indexes where name = 'idx_exp_m')
drop index idx_exp_m on Expdata

create index idx_exp_m on ExpData(machine)

/*------------------------------------------------
DISABLE CACHE and PARALLELISM
--------------------------------------------------*/
if exists (select 1 from sys.objects where name ='sp_flushBuffer' 
and schema_id= 1) drop procedure sp_flushBuffer;
go
create procedure sp_flushBuffer @flag integer
as begin 
	reconfigure with override;
	/*Configuration for parallelism*/
	exec sp_configure 'show advanced options', @flag;	
	reconfigure with override;

	/*0 means allowing parallelism*/
	/*1 means no parallelism*/
	exec sp_configure 'max degree of parallelism', @flag;
	reconfigure with override;	

	/*Force SQL Server to flush away the cache*/
	if @flag = 1 
	begin
		DBCC DROPCLEANBUFFERS;
		DBCC FREEPROCCACHE;
	end
end	
go

use $(database)
INSERT INTO expData VALUES('1','500');
INSERT INTO expData VALUES('2','500');
INSERT INTO expData VALUES('3','500');
INSERT INTO expData VALUES('4','500');
INSERT INTO expData VALUES('5','500');
INSERT INTO expData VALUES('6','500');
INSERT INTO expData VALUES('7','500');
INSERT INTO expData VALUES('8','500');
INSERT INTO expData VALUES('9','500');
INSERT INTO expData VALUES('10','500');
INSERT INTO expData VALUES('11','500');
INSERT INTO expData VALUES('12','500');
INSERT INTO expData VALUES('13','500');
INSERT INTO expData VALUES('14','500');
INSERT INTO expData VALUES('15','500');
INSERT INTO expData VALUES('16','500');
INSERT INTO expData VALUES('17','500');
INSERT INTO expData VALUES('18','500');
INSERT INTO expData VALUES('19','500');
INSERT INTO expData VALUES('20','500');
INSERT INTO expData VALUES('21','500');
INSERT INTO expData VALUES('22','500');
INSERT INTO expData VALUES('23','500');
INSERT INTO expData VALUES('24','500');
INSERT INTO expData VALUES('25','500');
INSERT INTO expData VALUES('26','500');
INSERT INTO expData VALUES('27','500');
INSERT INTO expData VALUES('28','500');
INSERT INTO expData VALUES('29','500');
INSERT INTO expData VALUES('30','500');
INSERT INTO expData VALUES('31','500');
INSERT INTO expData VALUES('32','500');
INSERT INTO expData VALUES('33','500');
INSERT INTO expData VALUES('34','500');
INSERT INTO expData VALUES('35','500');
INSERT INTO expData VALUES('36','500');
INSERT INTO expData VALUES('37','500');
INSERT INTO expData VALUES('38','500');
INSERT INTO expData VALUES('39','500');
INSERT INTO expData VALUES('40','500');
INSERT INTO expData VALUES('41','500');
INSERT INTO expData VALUES('42','500');
INSERT INTO expData VALUES('43','500');
INSERT INTO expData VALUES('44','500');
INSERT INTO expData VALUES('45','500');
INSERT INTO expData VALUES('46','500');
INSERT INTO expData VALUES('47','500');
INSERT INTO expData VALUES('48','500');
INSERT INTO expData VALUES('49','500');
INSERT INTO expData VALUES('50','500');
INSERT INTO expData VALUES('51','500');
INSERT INTO expData VALUES('52','500');
INSERT INTO expData VALUES('53','500');
INSERT INTO expData VALUES('54','500');
INSERT INTO expData VALUES('55','500');
INSERT INTO expData VALUES('56','500');
INSERT INTO expData VALUES('57','500');
INSERT INTO expData VALUES('58','500');
INSERT INTO expData VALUES('59','500');
INSERT INTO expData VALUES('60','500');
INSERT INTO expData VALUES('61','500');
INSERT INTO expData VALUES('62','500');
INSERT INTO expData VALUES('63','500');
INSERT INTO expData VALUES('64','500');
INSERT INTO expData VALUES('65','500');
INSERT INTO expData VALUES('66','500');
INSERT INTO expData VALUES('67','500');
INSERT INTO expData VALUES('68','500');
INSERT INTO expData VALUES('69','500');
INSERT INTO expData VALUES('70','500');
INSERT INTO expData VALUES('71','500');
INSERT INTO expData VALUES('72','500');
INSERT INTO expData VALUES('73','500');
INSERT INTO expData VALUES('74','500');
INSERT INTO expData VALUES('75','500');
INSERT INTO expData VALUES('76','500');
INSERT INTO expData VALUES('77','500');
INSERT INTO expData VALUES('78','500');
INSERT INTO expData VALUES('79','500');
INSERT INTO expData VALUES('80','500');
INSERT INTO expData VALUES('81','500');
INSERT INTO expData VALUES('82','500');
INSERT INTO expData VALUES('83','500');
INSERT INTO expData VALUES('84','500');
INSERT INTO expData VALUES('85','500');
INSERT INTO expData VALUES('86','500');
INSERT INTO expData VALUES('87','500');
INSERT INTO expData VALUES('88','500');
INSERT INTO expData VALUES('89','500');
INSERT INTO expData VALUES('90','500');
INSERT INTO expData VALUES('91','500');
INSERT INTO expData VALUES('92','500');
INSERT INTO expData VALUES('93','500');
INSERT INTO expData VALUES('94','500');
INSERT INTO expData VALUES('95','500');
INSERT INTO expData VALUES('96','500');
INSERT INTO expData VALUES('97','500');
INSERT INTO expData VALUES('98','500');
INSERT INTO expData VALUES('99','500');
INSERT INTO expData VALUES('100','500');

go