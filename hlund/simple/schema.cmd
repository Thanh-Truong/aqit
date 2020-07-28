REM Generating mapping files
call sqlcmd -S %address%  -U %username% -P %password% -o log.txt -e -v database=%database% -i schema.sql
call bcp %database%..sensor format nul -c -f sensorFMT.xml -x -S %address% -U %username% -P %password% -t ;
call bcp %database%..machine format nul -c -f machineFMT.xml -x -S %address% -U %username% -P %password% -t ;  
call bcp %database%..measuresA format nul -c -f measuresAFMT.xml -x -S %address% -U %username% -P %password% -t ; 