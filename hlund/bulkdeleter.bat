call %Amos_HOME%\aqit\hlund\config.cmd
pushd %Amos_HOME%\aqit\hlund\
call sqlcmd -S %address%  -U %username% -P %password% -o logdeleter.txt -e -v database=%database% -i bulkdeleter.sql
popd