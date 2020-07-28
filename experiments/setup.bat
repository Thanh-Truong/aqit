set mexi=1

REM -- Environment variables (database engine, address, user, pass..)----
call config.cmd

REM -- Install Amos II and Javaamos----
REM pushd ..\..\bin
REM call install.bat
REM popd

REM -- Back to current directory----
cd \AmosNT\aqit\experiments\


REM http://www.sqlbook.com/SQL-Server/SQLCMD-command-line-utility-13.aspx
REM http://msdn.microsoft.com/en-us/library/ms180944.aspx

REM -- Making database (schema + data) for AQIT10M----
set database=aqit10M
sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i sqlserver\error_detection\schema.sql


set datafile=D:\Generated_Machine_Data\data%database%.csv
sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i sqlserver\error_detection\bulk.sql

REM -- Making database (schema + data) for AQIT20M----
set database=aqit20M
sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i sqlserver\error_detection\schema.sql


set datafile=D:\Generated_Machine_Data\data%database%.csv
sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i sqlserver\error_detection\bulk.sql


REM -- Making database (schema + data) for AQIT30M----
set database=aqit30M
sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i sqlserver\error_detection\schema.sql


set datafile=D:\Generated_Machine_Data\data%database%.csv
sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i sqlserver\error_detection\bulk.sql


REM -- Making database (schema + data) for AQIT40M----
set database=aqit40M
sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i sqlserver\error_detection\schema.sql


set datafile=D:\Generated_Machine_Data\data%database%.csv
sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i sqlserver\error_detection\bulk.sql


REM -- Making database (schema + data) for AQIT50M----
set database=aqit50M
sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i sqlserver\error_detection\schema.sql


set datafile=D:\Generated_Machine_Data\data%database%.csv
sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i sqlserver\error_detection\bulk.sql


REM -- Making database (schema + data) for AQIT60M----
set database=aqit60M
sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i sqlserver\error_detection\schema.sql


set datafile=D:\Generated_Machine_Data\data%database%.csv
sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i sqlserver\error_detection\bulk.sql


REM -- Making database (schema + data) for AQIT70M----
set database=aqit70M
sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i sqlserver\error_detection\schema.sql


set datafile=D:\Generated_Machine_Data\data%database%.csv
sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i sqlserver\error_detection\bulk.sql


REM -- Making database (schema + data) for AQIT80M----
set database=aqit80M
sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i sqlserver\error_detection\schema.sql


set datafile=D:\Generated_Machine_Data\data%database%.csv
sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i sqlserver\error_detection\bulk.sql


REM -- Making database (schema + data) for AQIT90M----
set database=aqit90M
sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i sqlserver\error_detection\schema.sql


set datafile=D:\Generated_Machine_Data\data%database%.csv
sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i sqlserver\error_detection\bulk.sql


REM -- Making database (schema + data) for AQIT100M----
set database=aqit100M
sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i sqlserver\error_detection\schema.sql


set datafile=D:\Generated_Machine_Data\data%database%.csv
sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i sqlserver\error_detection\bulk.sql