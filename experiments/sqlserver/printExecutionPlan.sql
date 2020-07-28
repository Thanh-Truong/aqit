use aqit;
go
set showplan_text on
go
select x from tblbtree where x < 100 and x > 20;
go
select x from tblbtree where x+ 1 < 100 and x + 1> 20;
go


