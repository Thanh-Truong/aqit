use $(database)
go
/*Drop table test*/
if exists (select 1 from sys.tables where name='tbltest' and  schema_id=1) 
           drop table tbltest

go
create table tbltest
(x float not null,
 y float not null) 
go 
