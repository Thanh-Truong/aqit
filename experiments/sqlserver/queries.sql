use aqit;

/*SQL Server utilizes B-tree index*/
select x from tblbtree where x > 500000-5 and  x < 500003 -5;
GO
/*SQL Server does not utilize B-tree index*/
select x from tblbtree where x + 5> 500000 and  x + 5< 500003;

set showplan_text on
go