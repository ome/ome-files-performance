@echo off

exec java -classpath "target/classes;target/dependency/*" ome.files.performance.OMETIFFPerformance "$@"
