use $(database)
go
/*Statistic of space used*/
exec sp_spaceused $(table);
go
/*Statistic of indexed mv column*/
dbcc show_statistics('$(table)', idx_$(table)_v) 
with stat_header;
go
select min(mv) as min, max(mv) as max, avg(mv) as avg 
from $(table);
go
/*How long this the measurement was conducted ?*/
select min(ts) as start, max(ts) as finish
from $(table);

/*Sample data */
select count(*) from (select ts, mv as avg 
from measuredValueREG408
order by ts) as tmp

