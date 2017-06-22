@echo off
REM Build with Jenkins CI.  This script is intended for use with the OME
REM Jenkins CI infrastructure, though it may be useful as an example for
REM how one might use various cmake options.

REM So that statements like "set" work inside nested conditionals
setlocal ENABLEDELAYEDEXPANSION
setlocal ENABLEEXTENSIONS

REM Run Java tiling performance tests
for %%T in (neff-histopathology tubhiswt) do (
    set test=%%T
    set input=unknown

    cd %WORKSPACE%\source

    if [!test!] == [neff-histopathology] (
        set input=%DATA_DIR%\ndpi\neff-histopathology\Bazla-14-100-brain - 2015-06-19 23.34.11.ndpi

        REM Run Java tiling performance tests - very large image
        REM call mvn -P tiling -Dtest.iterations=%iterations% -Dtest.input=!input! -Dtest.tileXStart=122880 -Dtest.tileYStart=103424 -Dtest.autoTile=false -Dtest.output=%outdir%\!test!-java.ome.xml -Dtest.results=%resultsdir%\!test!-tiling-win-java.tsv exec:java
        REM for /L %%I IN (1,1,!iterations!) do (
            REM call mvn -P tiling -Dtest.iterations=1 -Dtest.input=!input! -Dtest.tileXStart=122880 -Dtest.tileYStart=103424 -Dtest.autoTile=false -Dtest.output=%outdir%\!test!-java.ome.xml -Dtest.results=%resultsdir%\!test!-tiling-win-java-%%I.tsv exec:java
        REM )

        REM Run Java tiling performance tests - large image
        call mvn -P tiling -Dtest.iterations=%iterations% -Dtest.input=!input! -Dtest.tileXStart=15360 -Dtest.tileYStart=12928 -Dtest.series=1 -Dtest.autoTile=false -Dtest.output=%outdir%\!test!-java.ome.xml -Dtest.results=%resultsdir%\!test!-tiling—large-win-java.tsv exec:java
        for /L %%I IN (1,1,!iterations!) do (
            call mvn -P tiling -Dtest.iterations=1 -Dtest.input=!input! -Dtest.tileXStart=15360 -Dtest.tileYStart=12928 -Dtest.series=1 -Dtest.autoTile=false -Dtest.output=%outdir%\!test!-java.ome.xml -Dtest.results=%resultsdir%\!test!-tiling-large-win-java-%%I.tsv exec:java
        )

        REM Run Java tiling performance tests - medium image
        call mvn -P tiling -Dtest.iterations=%iterations% -Dtest.input=!input! -Dtest.tileXStart=7680 -Dtest.tileYStart=6464 -Dtest.autoTile=false -Dtest.tileOperator="-" -Dtest.tileIncrement=64 -Dtest.series=2 -Dtest.output=%outdir%\!test!-java.ome.xml -Dtest.results=%resultsdir%\!test!-tiling-medium—win-java.tsv exec:java
        for /L %%I IN (1,1,!iterations!) do (
            call mvn -P tiling -Dtest.iterations=1 -Dtest.input=!input! -Dtest.tileXStart=7680 -Dtest.tileYStart=6464 -Dtest.autoTile=false -Dtest.tileOperator="-" -Dtest.tileIncrement=64 -Dtest.series=2 -Dtest.output=%outdir%\!test!-java.ome.xml -Dtest.results=%resultsdir%\!test!-tiling—medium-win-java-%%I.tsv exec:java
        )
    )
    if [!test!] == [tubhiswt] (
        set input=%DATA_DIR%\tubhiswt-4D\tubhiswt_C0_TP0.ome.tif

        REM Run Java tiling performance tests - auto tiling
        call mvn -P tiling -Dtest.iterations=%iterations% -Dtest.input=!input! -Dtest.tileXStart=512 -Dtest.tileYStart=512 -Dtest.output=%outdir%\!test!-java.ome.xml -Dtest.results=%resultsdir%\!test!-tiling—autotile-win-java.tsv exec:java
        for /L %%I IN (1,1,!iterations!) do (
            call mvn -P tiling -Dtest.iterations=1 -Dtest.input=!input! -Dtest.tileXStart=512 -Dtest.tileYStart=512 -Dtest.output=%outdir%\!test!-java.ome.xml -Dtest.results=%resultsdir%\!test!-tiling—autotile-win-java-%%I.tsv exec:java
        )

        REM Run Java tiling performance tests - manual tiling
        call mvn -P tiling -Dtest.iterations=%iterations% -Dtest.input=!input! -Dtest.tileXStart=512 -Dtest.tileYStart=512 -Dtest.autoTile=false -Dtest.output=%outdir%\!test!-java.ome.xml -Dtest.results=%resultsdir%\!test!-tiling—noauto-win-java.tsv exec:java
        for /L %%I IN (1,1,!iterations!) do (
            call mvn -P tiling -Dtest.iterations=1 -Dtest.input=!input! -Dtest.tileXStart=512 -Dtest.tileYStart=512 -Dtest.autoTile=false -Dtest.output=%outdir%\!test!-java.ome.xml -Dtest.results=%resultsdir%\!test!-tiling—noauto-win-java-%%I.tsv exec:java
        )
    )
)
