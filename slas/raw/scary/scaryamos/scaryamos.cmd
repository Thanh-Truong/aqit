REM Make scaryamos.dmp
pushd regress
amos2 -o "load_lisp('put_scary.lsp');quit;"

REM Load scaryamos.dmp and test
amos2 scaryamos.dmp -o "load_lisp('get_scary.lsp');quit;"
popd