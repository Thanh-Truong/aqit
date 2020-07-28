REM Building database image
pushd ..\simulator
call ..\..\bin\amos2 -o "<'sigstreamgen2.osql'; save 'sim.dmp'; quit;"

REM Generating data
call ..\..\bin\amos2  sim.dmp -o "generateData('D:\\Generated_Machine_Data\dataaqit1.csv', 3000);quit;" 

popd

call config.cmd
REM Cleaning and setting up schema
set database=aqit10M
sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i sqlserver\error_detection\schema.sql

REM cd D:\\Generated_Machine_Data\\
REM @echo off & setlocal EnableDelayedExpansion
REM set row=
REM for /F "delims=" %%j in (D:\\Generated_Machine_Data\\dataaqit1.csv) do (
REM   if  defined row echo.!row!>> cd D:\\Generated_Machine_Data\\dataaqit.new
REM   set row=%%j
REM )

REM Bulk loading data
set datafile=D:\\Generated_Machine_Data\\dataaqit.new
set size=300
sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i sqlserver\error_detection\bulk.sql
