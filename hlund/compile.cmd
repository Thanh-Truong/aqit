REM Using libraries logdir.jar, javascsq.jar
set CLASSPATH=%CLASSPATH%;%AMOS_HOME%\logdir\lib\logdir.jar;%AMOS_HOME%\bin\javascsq.jar

REM Building LOGDIR
pushd ..\..\logdir\
call compile
call mkdmp
popd

REM Building SVALI
pushd ..\..\validate\
call compile > tmp.txt
call mkdmp
call mkdll
popd

REM Buildinig LOGDIR wrapper
pushd ..\..\logdir\hlund\
call mkdmp
popd

REM Cleaning dump files
IF EXIST bulk.dmp del bulk.dmp
copy ..\..\logdir\hlund\hlund.dmp bulk.dmp

REM Adding some AQIT pieces
call java JavaSCSQ bulk.dmp -o "load_lisp('bulk.lsp'); save 'bulk.dmp';quit;" 

@echo on
REM Setting up the enviroment
call config.cmd

REM Deleting and creating a test database
call sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i schema.sql

REM Generating format XML file which is a mapping (columns vs row headers)
call bcp %database%..%table% format nul -c -f %table%FMT.xml -x -S %address% -U %username% -P %password% -t %fieldterminator% -o log.txt
call bcp %database%..logfile format nul -c -f logfileFMT.xml -x -S %address% -U %username% -P %password% -t %fieldterminator% -o log.txt


if not exist ./tmp mkdir tmp
if exist tmp\*.csv del tmp\*.csv


REM Delete bulkdeleter forcefully
Schtasks /delete /TN bulkdeleter /F