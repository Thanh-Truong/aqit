REM -- Environment variables----
set engine=SQLSERVER
set database=test
set address=udblserver1.it.uu.se
set username=udbl
set password=udbl
set table=tbltest
set fieldterminator=;


REM 1. Deleting and creating a test database
sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i schema.sql

REM 2. Generating data and writting out to log file
call ..\..\bin\amos2  -o "write_csv((select {i*1.5, (i+1) /3} from Number i where i in iota(1, 5)), 'test.csv', ';');quit;" 

REM 2. Generating format XML file which is a mapping (columns vs row headers)
bcp %database%..%table% format nul -c -f TableFMT.xml -x -S %address% -U %username% -P %password% -t %fieldterminator%


REM 3.(Bulk) loading data
set datafile=%AMOS_HOME%aqit\examples\test.csv

REM sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i bulk.sql
bcp %database%..%table% in %datafile% -f TableFMT.xml -S %address% -U %username% -P %password%

