@echo off
REM Build with Jenkins CI.  This script is intended for use with the OME
REM Jenkins CI infrastructure, though it may be useful as an example for
REM how one might use various cmake options.

REM So that statements like "set" work inside nested conditionals
setlocal ENABLEDELAYEDEXPANSION
setlocal ENABLEEXTENSIONS

for %%T in (bbbc mitocheck tubhiswt) do (
    set test=%%T
    set input=unknown
    if [!test!] == [bbbc] (
        set input=%DATA_DIR%\BBBC\NIRHTa-001.ome.tiff
    )
    if [!test!] == [mitocheck] (
        set input=%DATA_DIR%\mitocheck\00001_01.ome.tiff
    )
    if [!test!] == [tubhiswt] (
        set input=%DATA_DIR%\tubhiswt-4D\tubhiswt_C0_TP0.ome.tif
    )

    cd %WORKSPACE%\source

    REM Run Java metadata performance tests
    call mvn -P metadata -Dtest.iterations=%iterations% -Dtest.input=!input! -Dtest.output=%outdir%\!test!-java.ome.xml -Dtest.results=%resultsdir%\!test!-metadata-win-java.tsv exec:java
    for /L %%I IN (1,1,!iterations!) do (
        call mvn -P metadata -Dtest.iterations=1 -Dtest.input=!input! -Dtest.output=%outdir%\!test!-java.ome.xml -Dtest.results=%resultsdir%\!test!-metadata-win-java-%%I.tsv exec:java
    )

    REM Execute C++ performance tests
    cd "%WORKSPACE%"

    REM Run C++ metadata tests
    install\bin\metadata-performance %iterations% !input!  %outdir%\!test!-cpp.ome.xml %resultsdir%\!test!-metadata-win-cpp.tsv
    for /L %%I IN (1,1,!iterations!) do (
        install\bin\metadata-performance 1 !input!  %outdir%\!test!-cpp.ome.xml %resultsdir%\!test!-metadata-win-cpp-%%I.tsv
    )
)
