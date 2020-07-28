/*Choose database*/
use $(database)
go
BULK INSERT logData
FROM '$(datafile)'
WITH 
(
FIELDTERMINATOR =';',
ROWTERMINATOR ='\n',
LASTROW =$(size),
MAXERRORS = 2
)
go