@echo ---------------------------------------------------------------------
@echo Test AQIT simple on 1 D
@echo ---------------------------------------------------------------------
%AMOS_HOME/%amos2  -o "<'simple.osql'; quit;"


@echo ---------------------------------------------------------------------
@echo Test AQIT on multidimensional data. 
@echo ---------------------------------------------------------------------
pushd ..\..\applications\ExtensibleIndexes\XT
%AMOS_HOME/%amos2  -o " <'regress.osql'; load_amosql('similarity_test.osql'); load_lisp('test_transformer.lsp');quit;"
popd


@echo ---------------------------------------------------------------------
@echo Test Numerical SQL translator. MySQL localhost should be running
@echo ---------------------------------------------------------------------
REM pushd ..\..\wrappers\JDBC\regress
REM set portdb=3306
REM call javaamos  -o " <'num.osql';quit;"
REM popd


@echo ---------------------------------------------------------------------
@echo Test extended SQL Parser, AQIT, and SQL Translator. 
@echo No backend database needed
@echo ---------------------------------------------------------------------
%AMOS_HOME/%amos2  -o " <'simple_sql.osql';quit;"

@echo ---------------------------------------------------------------------
@echo Test extended SQL Parser, AQIT, and SQL Translator. 
@echo SQL Server at UDBLSERVER1.IT.UU.SE will be a backend database by default
@echo Configuration can be altered at config.cmd
@echo ---------------------------------------------------------------------
REM pushd ..\hlund\experiments\
REM call config.cmd
REM call javaamos -o "<'queries-sql.osql'; quit;"
REM popd

REM Lightweight database
@echo set database=aqit
@echo call javaamos  -o " <'complex_sql.osql';quit;"
