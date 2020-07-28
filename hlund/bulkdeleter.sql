use $(database)
go
/*sp_spaceused use $(table)*/
/*delete all data if table grows big 120 milion rows.
It is better to base on timestamp*/
if (select COUNT(*) from $(table)) > 120000000 delete from  $(table)
go
