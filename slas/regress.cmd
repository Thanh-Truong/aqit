call install.cmd
call config\config.cmd > null
REM -------------------------Testing RAW FILE----------------------------
call slas  -L "regress\test_raw_proxy.lsp" -l "(quit)"
REM -------------------------Testing LOGGER------------------------------
pushd raw\logger\Release
logger
popd