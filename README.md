# OME Files Benchmark

## Introduction

The current repository includes a set of benchmarks used to test the following
software:

-   [OME Files 0.3.1](http://downloads.openmicroscopy.org/ome-files-cpp/0.3.1/)
-   [Bio-Formats 5.3.4](http://downloads.openmicroscopy.org/bio-formats/5.3.4/)
    both using the Java Virtual Machine and the
    [Jace C++ bindings](https://github.com/ome/bio-formats-jace)

The benchmark suite has been executed under Windows Server 2008 and Ubuntu
16.04 with the exception of the JACE C++ bindings which we have only built
under Ubuntu 16.04 using JDK 7.

## Benchmark datasets

The reference datasets used for the benchmark are compose of three public OME-TIFF filesets representing different aspects of the OME Data model:

-   a typical 5D fluorescence image - see  http://downloads.openmicroscopy.org/images/OME-TIFF/2016-06/tubhiswt-4D/
-   a plate generated from the public [Broad Bioimage Benchmark Collection](https://data.broadinstitute.org/bbbc/) and exported as an OME-TIFF - see http://downloads.openmicroscopy.org/images/OME-TIFF/2016-06/BBBC/ [BBBC](http://downloads.openmicroscopy.org/images/OME-TIFF/2016-06/BBBC/)
-   a metadata-rich (13K Regions of Interest) time-lapse sequence from the  [Mitocheck](http://downloads.openmicroscopy.org/images/OME-TIFF/2016-06/mitocheck/) project - see http://downloads.openmicroscopy.org/images/OME-TIFF/2016-06/mitocheck/

For more references and description, see https://www.openmicroscopy.org/site/support/ome-model/ome-tiff/data.html.

## Benchmark execution and metrics

For each of the datasets above, the following benchmark pipelines were executed:

-   the metadata is extracted TIFF tag and converted into OME-XML then
    written down as OME-XML file
-   the pixel data was read from the OME-TIFF datasets using the API then
    written down as OME-TIFF file

For both pipelines, the execution time of the reading and writing steps is
measured by benchmark script using the standard system utility function and
stored in a tabular form.

## Building and executing the benchmark scripts

### Windows

The benchmark scripts have been executed on a Windows 2008 Server. The other
build requirements are [Cmake](https://cmake.org/), 
[Maven](http://maven.apache.org/),
[Visual Studio](https://www.visualstudio.com/) and a local version of the 
standalone OME Files bundle for the chosen Visual Studio version.

In the context of our benchmark, we used
[Jenkins](https://jenkins.io/index.html) to trigger the Windows benchmark
builds. The benchmark script is available under [jenkins_build.bat]([scripts/jenkins_build.bat).

To build the OME Files performance scripts manually, within a `build` directory
run the following `cmake` command:

    $ cmake -G "Ninja" -DCMAKE_VERBOSE_MAKEFILE:BOOL=%verbose%
      -DCMAKE_INSTALL_PREFIX:PATH=%installdir% -DCMAKE_BUILD_TYPE=%build_type%
     "-DCMAKE_PREFIX_PATH=%OME_FILES_BUNDLE%" 
      -DCMAKE_PROGRAM_PATH=%OME_FILES_BUNDLE%\bin
      -DCMAKE_LIBRARY_PATH=%OME_FILES_BUNDLE%\lib 
      -DBOOST_ROOT=%OME_FILES_BUNDLE% %sourcedir% 
    $ cmake --build .
    $ cmake --build . --target install

The Bio-Formats performance script can be built within the source directory
using Maven:

    $ cd source
    $ call mvn clean install

### Linux

The Linux benchmark was performed on Ubuntu 16.04. To ease the distribution and
reproducibility of the suite, the benchmark environment is built using
[Docker](https://www.docker.com/) via a [Dockerfile](Dockerfile). To build the
benchmark Docker image, run:

    $ docker build -t ome-files-performance .

In order to execute the benchmark scripts, download the benchmark datasets
under a local folder e.g. `/tmp/benchmark_data` then mount this local folder as
a  `/data` volume and run the Docker image:

    $ docker run --rm -it -v /data:/data ome-files-performance

This will execute the [run_benchmarking](scripts/run_benchmarking) script and
store the output of the benchmark under `/data/out` and the tabular results 
under `/data/results`.

## Benchmark results

### Tabular results

The [results](results) folder contains the final set of results generated using
the benchmark procedure described above.

### Metrics

The following metrics have bee

## References

