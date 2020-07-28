setlocal enabledelayedexpansion
for /f %%a IN ('dir /b *measured*.csv') do (
set table=%%~na
call sqlcmd -S %address%  -U %username% -P %password% -o statistic%%~na.txt -e -v database=%database% -i statistic.sql
)
endlocal