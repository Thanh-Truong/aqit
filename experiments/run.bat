REM -- Environment variables (database engine, address, user, pass..)----
call config.cmd
set database=aqit10M
sqlcmd -S %address%  -U %username% -P %password% -e -v database=%database% -i cooldown.sql
call javaamos -o "<'experiment.osql';quit;"
set database=aqit20M
sqlcmd -S %address%  -U %username% -P %password% -e -v database=%database% -i cooldown.sql
call javaamos -o "<'experiment.osql';quit;"
set database=aqit30M
sqlcmd -S %address%  -U %username% -P %password% -e -v database=%database% -i cooldown.sql
call javaamos -o "<'experiment.osql';quit;"
set database=aqit40M
sqlcmd -S %address%  -U %username% -P %password% -e -v database=%database% -i cooldown.sql
call javaamos -o "<'experiment.osql';quit;"
set database=aqit50M
sqlcmd -S %address%  -U %username% -P %password% -e -v database=%database% -i cooldown.sql
call javaamos -o "<'experiment.osql';quit;"
set database=aqit60M
sqlcmd -S %address%  -U %username% -P %password% -e -v database=%database% -i cooldown.sql
call javaamos -o "<'experiment.osql';quit;"
set database=aqit70M
sqlcmd -S %address%  -U %username% -P %password% -e -v database=%database% -i cooldown.sql
call javaamos -o "<'experiment.osql';quit;"
set database=aqit80M
sqlcmd -S %address%  -U %username% -P %password% -e -v database=%database% -i cooldown.sql
call javaamos -o "<'experiment.osql';quit;"
set database=aqit90M
sqlcmd -S %address%  -U %username% -P %password% -e -v database=%database% -i cooldown.sql
call javaamos -o "<'experiment.osql';quit;"
set database=aqit100M
sqlcmd -S %address%  -U %username% -P %password% -e -v database=%database% -i cooldown.sql
call javaamos -o "<'experiment.osql';quit;"
set database=aqit200M
sqlcmd -S %address%  -U %username% -P %password% -e -v database=%database% -i cooldown.sql
call javaamos -o "<'experiment.osql';quit;"



