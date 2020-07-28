REM Bulk loading 
bcp %database%..machine in machine.csv -f machineFMT.xml -S %address% -U %username% -P %password%

bcp %database%..sensor in sensor.csv -f sensorFMT1.xml -S %address% -U %username% -P %password%

setlocal enabledelayedexpansion
for /f %%a IN ('dir /b *measures*.csv') do (
set table=%%~na
call sqlcmd -S %address%  -U %username% -P %password% -e -v database=%database% -i partion_schema.sql
call bcp %database%..%%~na in %%a -f measuresAFMT.xml -S %address% -U %username% -P %password% -b 1000 -m 1000 -k
)
endlocal
