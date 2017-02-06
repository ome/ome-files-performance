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
if exist "results" (
    rmdir /s /q "results"
)
REM if exist "bio-formats-jace-build" (
REM    rmdir /s /q "bio-formats-jace-build"
REM )
mkdir build
mkdir install
mkdir results

REM cd %WORKSPACE%\bio-formats-jace
REM call mvn -DskipTests clean package cppwrap:wrap dependency:copy-dependencies
REM Correct broken and outdated Boost checks
REM copy %WORKSPACE%\source\cmake\JACEPrerequisites.cmake target\cppwrap\jace\Prerequisites.cmake || exit /b

REM mkdir %WORKSPACE%\bio-formats-jace-build
REM cd %WORKSPACE%\bio-formats-jace-build
REM cmake -G "Visual Studio 14 2015 Win64" ^
REM   -DCMAKE_VERBOSE_MAKEFILE:BOOL=%verbose% ^
REM   -DCMAKE_BUILD_TYPE=%build_type% ^
REM   -DCMAKE_PREFIX_PATH=%OME_FILES_BUNDLE% ^
REM   -DCMAKE_PROGRAM_PATH=%OME_FILES_BUNDLE%\bin ^
REM   -DCMAKE_LIBRARY_PATH=%OME_FILES_BUNDLE%\lib ^
REM   -DJ2L_WIN_BUILD_DEBUG=OFF ^
REM   -DBOOST_ROOT=%OME_FILES_BUNDLE% ^
REM   "-DBoost_ADDITIONAL_VERSIONS=1.62;1.62.0;1.63;1.63.0" ^
REM   %WORKSPACE%\bio-formats-jace\target\cppwrap ^
REM   || exit /b
REM cmake --build . || exit /b
REM
REM set "PATH=%WORKSPACE%\bio-formats-jace-build\dist\bio-formats-jace;%PATH%"

cd %WORKSPACE%\build

cmake -G "Ninja" ^
  -DCMAKE_VERBOSE_MAKEFILE:BOOL=%verbose% ^
  -DCMAKE_INSTALL_PREFIX:PATH=%installdir% ^
  -DCMAKE_BUILD_TYPE=%build_type% ^
  "-DCMAKE_PREFIX_PATH=%OME_FILES_BUNDLE%;%WORKSPACE%\bio-formats-jace-build\dist\bio-formats-jace" ^
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

REM Run Java metadata performance tests

call mvn -P metadata -Dtest.iterations=10 -Dtest.input=%DATA_DIR%\BBBC\NIRHTa-001.ome.tiff -Dtest.output=bbbc.ome.xml -Dtest.results=%WORKSPACE%\results\bbbc-metadata-win-java.tsv exec:java
call mvn -P metadata -Dtest.iterations=10 -Dtest.input=%DATA_DIR%\mitocheck\00001_01.ome.tiff -Dtest.output=mitocheck.ome.xml -Dtest.results=%WORKSPACE%\results\bbbc-mitocheck-win-java.tsv exec:java

REM Run Java pixels performance tests

call mvn -P pixels -Dtest.iterations=5 -Dtest.input=%DATA_DIR%\BBBC\NIRHTa-001.ome.tiff -Dtest.output=bbbc.ome.tiff -Dtest.results=%WORKSPACE%\results\bbbc-pixeldata-win-java.tsv exec:java
call mvn -P pixels -Dtest.iterations=5 -Dtest.input=%DATA_DIR%\mitocheck\00001_01.ome.tiff -Dtest.output=mitocheck.ome.tiff -Dtest.results=%WORKSPACE%\results\mitocheck-pixeldata-win-java.tsv exec:java

REM Execute C++ performance tests
cd "%WORKSPACE%"

REM Run C++ metadata tests

install\bin\metadata-performance 10 %DATA_DIR%\BBBC\NIRHTa-001.ome.tiff bbbc.ome.xml results/bbbc-metadata-win-cpp.tsv
install\bin\metadata-performance 10 %DATA_DIR%\mitocheck\00001_01.ome.tiff mitocheck.ome.xml results/mitocheck-metadata-win-cpp.tsv

REM Run C++ pixels performance tests
install\bin\pixels-performance 5 %DATA_DIR%\BBBC\NIRHTa-001.ome.tiff bbbc.ome.tiff results/bbbc-pixeldata-win-cpp.tsv
install\bin\pixels-performance 5 %DATA_DIR%\mitocheck\00001_01.ome.tiff mitocheck.ome.tiff results/mitocheck-pixeldata-win-cpp.tsv

