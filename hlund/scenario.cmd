set CLASSPATH=%CLASSPATH%;%AMOS_HOME%\logdir\lib\logdir.jar;%AMOS_HOME%\bin\javascsq.jar
start /separate run.cmd -o "< 'bulkloader.osql';"
start /separate run.cmd -o "< 'file_reporter.osql';" 
start /separate run.cmd -o "copier('C://udbl//VortexData//hagglunds//LogDir1//E01PS10-2991//E01PS10-2991//','D://Generated_Machine_Data//Hagglund//', 5);"

REM Schedule bulkdeleter to run every 45 minutes. If size of logdata table
REM is too big, bulkdeleter wipes them out. 
SCHTASKS /Create /TN bulkdeleter /SC MINUTE /MO 45 /TR %AMOS_HOME%\aqit\hlund\bulkdeleter.bat
