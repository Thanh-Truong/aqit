REM --Compile simulator
REM msdev sim.dsp /MAKE "sim - Win32 Release" /CLEAN
REM msdev sim.dsp /MAKE "sim - Win32 Release" /NORECURSE /REBUILD

REM --Make data image
REM call sim ..\..\bin\amos2.dmp -o "<'init.osql'; save 'sim.dmp'; quit;"

call amos2 ..\..\bin\amos2.dmp -o "<'sigstreamgen2.osql'; save 'sim.dmp'; quit;"
