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

set iterations=1
set outdir=%WORKSPACE%\out
set resultsdir=%WORKSPACE%\results

set do_default=true
if exist "metadata" (
    call metadata.bat
    set do_default=false
)
if exist "pixeldata" (
    call pixeldata.bat
    set do_default=false
)
if exist "tiling" (
    call tiling.bat
    set do_default=false
)
if [%do_default%] == [true] (
    call metadata.bat
    call pixeldata.bat
    call tiling.bat
)