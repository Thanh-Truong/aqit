REM  Installing SLAS
svali -L "boot.lsp" -l "(rollout "\"slas.dmp"\") (quit)"

REM  Building lofix, logger and slaslogger
pushd raw\slaslogger
msdev slaslogger.dsp /MAKE "slaslogger - Win32 Release" /CLEAN
pushd ..\lofixP
msdev lofixP.dsp /MAKE "lofixP - Win32 Release" /NORECURSE /REBUILD
popd

pushd ..\lofixS
msdev lofixS.dsp /MAKE "lofixS - Win32 Release" /NORECURSE /REBUILD
popd

pushd ..\logger
msdev logger.dsp /MAKE "logger - Win32 Release" /NORECURSE /REBUILD
popd

msdev slaslogger.dsp /MAKE "slaslogger - Win32 Release" /NORECURSE /REBUILD

svali ..\aqit\slas\slas.dmp -l "(load-amosql "\"init.osql"\")(rollout "\"../../slas.dmp"\") (quit)"

popd