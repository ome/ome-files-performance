@echo off
REM Build with Jenkins CI.  This script is intended for use with the OME
REM Jenkins CI infrastructure, though it may be useful as an example for
REM how one might use various cmake options.

REM So that statements like "set" work inside nested conditionals
setlocal ENABLEDELAYEDEXPANSION
setlocal ENABLEEXTENSIONS

set "script=%0"

set "sourcedir=%WORKSPACE%\source"
set "builddir=%WORKSPACE%\build"
set "installdir=%WORKSPACE%\install"
set "artefactdir=%WORKSPACE%\artefacts"
set "cachedir=%WORKSPACE%\cache"

echo WORKSPACE=%WORKSPACE%
echo sourcedir=%sourcedir%
echo builddir=%builddir%
echo installdir=%installdir%
echo artefactdir=%artefactdir%
echo cachedir=%cachedir%

set build_type=Release
set build_arch=x64
set build_version=14
set build_system=MSBuild
set verbose=OFF

set "OME_HOME=%OME_FILES_BUNDLE%"
set "DATA_DIR=D:\data_performance"
set "PATH=C:\Tools\ninja;%OME_FILES_BUNDLE%\bin;%MAVEN_PATH%\bin;%JAVA_HOME%\bin;%PATH%"

echo "OME-Files Bundle: %OME_FILES_BUNDLE%"
java -version
javac -version

if [%build_version%] == [11] (
    call "%VS110COMNTOOLS%..\..\VC\vcvarsall.bat" %build_arch%
)
if [%build_version%] == [12] (
    call "%VS120COMNTOOLS%..\..\VC\vcvarsall.bat" %build_arch%
)
if [%build_version%] == [14] (
    call "%VS140COMNTOOLS%..\..\VC\vcvarsall.bat" %build_arch%
)

cd "%WORKSPACE%"
if exist "build" (
    rmdir /s /q "build"
)
if exist "install" (
    rmdir /s /q "install"
)
if exist "out" (
    rmdir /s /q "out"
)
if exist "results" (
    rmdir /s /q "results"
)

mkdir build
mkdir install
mkdir out
mkdir results

cd %WORKSPACE%\build

cmake -G "Ninja" ^
  -DCMAKE_VERBOSE_MAKEFILE:BOOL=%verbose% ^
  -DCMAKE_INSTALL_PREFIX:PATH=%installdir% ^
  -DCMAKE_BUILD_TYPE=%build_type% ^
  -DCMAKE_PREFIX_PATH=%OME_FILES_BUNDLE% ^
  -DCMAKE_PROGRAM_PATH=%OME_FILES_BUNDLE%\bin ^
  -DCMAKE_LIBRARY_PATH=%OME_FILES_BUNDLE%\lib ^
  -DBOOST_ROOT=%OME_FILES_BUNDLE% ^
  %sourcedir% ^
  || exit /b

cmake --build . || exit /b
cmake --build . --target install || exit /b

REM Build Java
cd "%WORKSPACE%"
cd source
call mvn clean install || exit /b

set iterations=20
set outdir=%WORKSPACE%\out
set resultsdir=%WORKSPACE%\results

for %%T in (bbbc mitocheck tubhiswt) do (
    set test=%%T
    set input=unknown
    if [!test!] == [bbbc] (
        set input=%DATA_DIR%\BBBC\NIRHTa-001.ome.tiff
        set inputglob=%DATA_DIR%\BBBC\NIRHTa-001.ome.tiff
    )
    if [!test!] == [mitocheck] (
        set input=%DATA_DIR%\mitocheck\00001_01.ome.tiff
        set inputglob=%DATA_DIR%\mitocheck\00001_01.ome.tiff
    )
    if [!test!] == [tubhiswt] (
        set input=%DATA_DIR%\tubhiswt-4D\tubhiswt_C0_TP0.ome.tif
        set inputglob=
        for /f "tokens=*" %%F in ('dir /b /a:-d "%DATA_DIR%\tubhiswt-4D\tubhiswt_*.tif"') do call set inputglob=%%inputglob%% "%%F"
    )

    cd %WORKSPACE%\source

    REM Run Java metadata performance tests
    call scripts\metadata-performance-java %iterations% !input! %outdir%\!test!-java.ome.xml %resultsdir%\!test!-metadata-win-java.tsv
    for /L %%I IN (1,1,!iterations!) do (
        call scripts\metadata-performance-java 1 !input! %outdir%\!test!-java.ome.xml %resultsdir%\!test!-metadata-win-java-%%I.tsv
    )

    REM Run Java pixels performance tests
    call scripts\pixels-performance-java %iterations% !inputglob! %outdir%\!test!-java.ome.tiff %resultsdir%\!test!-pixeldata-win-java.tsv
    for /L %%I IN (1,1,!iterations!) do (
        call scripts\pixels-performance-java 1 !inputglob! %outdir%\!test!-java.ome.tiff %resultsdir%\!test!-pixeldata-win-java-%%I.tsv
    )

    REM Run Java ometiff performance tests
    call scripts\ometiff-performance-java %iterations% !input! %outdir%\!test!-java.ome.tiff %resultsdir%\!test!-ometiffdata-win-java.tsv
    for /L %%I IN (1,1,!iterations!) do (
        call scripts\ometiff-performance-java 1 !input! %outdir%\!test!-java.ome.tiff %resultsdir%\!test!-ometiffdata-win-java-%%I.tsv
    )

    REM Execute C++ performance tests
    cd "%WORKSPACE%"

    REM Run C++ metadata tests
    install\bin\metadata-performance %iterations% !input!  %outdir%\!test!-cpp.ome.xml %resultsdir%\!test!-metadata-win-cpp.tsv
    for /L %%I IN (1,1,!iterations!) do (
        install\bin\metadata-performance 1 !input!  %outdir%\!test!-cpp.ome.xml %resultsdir%\!test!-metadata-win-cpp-%%I.tsv
    )

    REM Run C++ pixels performance tests
    install\bin\pixels-performance %iterations% !inputglob! %outdir%\!test!-cpp.ome.tiff %resultsdir%\!test!-pixeldata-win-cpp.tsv
    for /L %%I IN (1,1,!iterations!) do (
        install\bin\pixels-performance 1 !inputglob! %outdir%\!test!-cpp.ome.tiff %resultsdir%\!test!-pixeldata-win-cpp-%%I.tsv
    )

    REM Run C++ ometiff performance tests
    install\bin\ometiff-performance %iterations% !input! %outdir%\!test!-cpp.ome.tiff %resultsdir%\!test!-ometiffdata-win-cpp.tsv
    for /L %%I IN (1,1,!iterations!) do (
        install\bin\ometiff-performance 1 !input! %outdir%\!test!-cpp.ome.tiff %resultsdir%\!test!-ometiffdata-win-cpp-%%I.tsv
    )
)
