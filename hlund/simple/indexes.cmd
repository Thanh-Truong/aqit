setlocal enabledelayedexpansion
for /f %%a IN ('dir /b *measured*.csv') do (
set table=%%~na
call sqlcmd -S %address%  -U %username% -P %password% -e -v database=%database% -Q "use $(database); create index idx_$(table)_v on $(table)(mv)"
)
endlocal

