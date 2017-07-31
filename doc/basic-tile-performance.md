# Basic TIFF tile performance benchmark

These benchmarks measure the execution times associated with the
writing of TIFF files with a range of tile and strip size parameters
using the low level C++ TIFF wrappers around libtiff.

## Benchmark tests

The following tests were executed:

- pixeldata.write: synthetic pixeldata is written to disk as a plain
  TIFF using the ``TIFF`` API with varied image size, pixel type and
  tile and strip sizes
  ([C++](http://downloads.openmicroscopy.org/ome-files-cpp/0.4.0/24/docs/ome-files-bundle-docs-0.4.0-b24/ome-files/api/html/classome_1_1files_1_1tiff_1_1TIFF.html))

Each benchmark test records the real time in milliseconds before and
after each test, and computes the elapsed time from the difference.

## Benchmark execution

Instructions for building the tests are in the top-level [README.md](../README.md).

Run the `run_basic_tiling` script. If using Docker, execute:

    ./scripts/run_benchmarking basic-tiling

## Benchmark results

The [results](../results/) folder contains the final set of results
(`tile-test-*`) generated using the benchmark tests described above with
the following columns:

- `test.lang`: name of the benchmark environment (Java, C++)
- `test.name`: name of the benchmark test
- `test.file`: name of the benchmark dataset
- `proc.real`/`real`: execution time measured by the benchmark script

[Analysis](../scripts/basic_tiling.R) of the results produced the following figures:

- [Tile writing performance](../analysis/tile-test-write-performance.pdf) (measured)
- [Tile count](../analysis/tile-test-count.pdf) (computed)
- [File size relationship to tile size](../analysis/tile-test-write-size.pdf) (computed)
