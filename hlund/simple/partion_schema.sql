use $(database)
go
/*Drop table $(table)*/
if exists (select 1 from sys.tables where name='$(table)' and  schema_id=1) 
           drop table $(table)

go
create table $(table)
(m   int,
 s   int,
 bt  float,
 et  float,
 mv  float,
 primary key (m, s, bt)
)
go 
