REM Number of cycles in an iteration
set SIM_NUMC=60

REM height of inactive curve, max value of non intersting value
set SIM_HEIGHTN=150

REM length of a cycle 1s
set SIM_LENGTHC=2

REM Height of abnormal curve, max value of active data
set SIM_HEIGHTA=%SIM_HEIGHTN%

REM How fast  a peak grows
set SIM_HOWFAST=20

set SIM_POSITIVEVAL=1

REM Thresold Up = SIM_HEIGHTN*10
set SIM_THRESOLDU=1000

REM How many % of total data, abnormality happens
set SIM_PERCENT=0.05

REM Number of machine
set MAX_MACHINE=100

REM After the interval, a report is sent
set SIM_INTERVAL=5