use $(database)
go
/*Drop table machine*/
if exists (select 1 from sys.tables where name='machine' and  schema_id=1) 
           drop table machine

go
create table machine
(machineid   nvarchar(10),
 model       nvarchar(10),
 description nvarchar(50)) 
go 


/*Drop table logfile*/
if exists (select 1 from sys.tables where name='logfile' and  schema_id=1) 
           drop table logfile

go
create table logfile
(fileid      bigint not null,
 filename    nvarchar(100) not null,
 deliveredtime datetime null) 
go 


/*Drop table logdata*/
if exists (select 1 from sys.tables where name='$(table)' and  schema_id=1) 
           drop table  $(table)

create table $(table)
(fileid   bigint not null,
 time     datetime not null,
 variable nvarchar(50) not null,
 value    float not null) 
go 


