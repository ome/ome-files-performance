@echo off

set params=%1
:argloop
shift
if [%1]==[] goto afterargloop
set params=%params% %1
goto argloop
:afterargloop

java -classpath "target/classes;target/dependency/*" ome.files.performance.OMETIFFPerformance %params%
