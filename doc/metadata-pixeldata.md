# Metadata and pixeldata benchmark

These benchmarks measure the execution times associated with the reading and
writing of the metadata and pixeldata of various datasets.
See this
[reference](https://github.com/openmicroscopy/ome-files-performance/tree/v0.1.1)
for a complete execution of this benchmark including results, analysis and
discussion.

## Benchmark datasets

Three public reference OME-TIFF datasets were used for performance
tests. For each dataset, we computed the metadata size-- the size in
bytes of the raw OME-XML string stored in the ImageDescription TIFF
tag-- and the pixeldata size-- the size in bytes of the binary pixel
data stored as TIFF. The test datasets are:

- “5D”, a multi-dimensional fluorescence image with 10 Z-sections, 2
  channels, 43 timepoints available at
  https://downloads.openmicroscopy.org/images/OME-TIFF/2016-06/tubhiswt-4D/.
  The metadata size is 176KiB and the size of the pixeldata is 216MiB.
- “Plate”, a plate containing 384 wells and 6 fields, derived from the
  [Broad Bioimage Benchmark
  Collection](https://data.broadinstitute.org/bbbc/) resource
  described in [Ljosa V, Sokolnicki KL, Carpenter AE (2012). Annotated
  high-throughput microscopy image sets for validation. Nature Methods
  9(7):637](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3627348/) and
  available at
  https://downloads.openmicroscopy.org/images/OME-TIFF/2016-06/BBBC/. The
  metadata size is 2.3MiB and the size of the pixeldata is 3.4GiB.
- “ROI”, a time-lapse sequence with ~13K regions of interest, derived
  from the [MitoCheck project](http://www.mitocheck.org/) described in
  [Neumann B et al. (2010). Phenotypic profiling of the human genome
  by time-lapse microscopy reveals cell division genes. Nature
  464(7289):721](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3108885/)
  and available at
  https://downloads.openmicroscopy.org/images/OME-TIFF/2016-06/MitoCheck/.
  The metadata size is 3.2MiB and the size of the pixeldata is 130MiB.

The datasets were chosen to test different aspects of library
performance. The Plate and ROI datasets are both single OME-TIFF
derived from real-world examples where the file content is either
dominated by the pixeldata or the metadata. 5D represents file layouts
where the pixeldata is distributed over multiple files. For more
information, see
https://www.openmicroscopy.org/site/support/ome-model/ome-tiff/data.html.


## Benchmark tests

For each of the datasets above, four benchmark tests were executed:

- metadata.read: the metadata is extracted from the OME-TIFF
  ImageDescription tag and converted into OME Data Model objects using
  the ``createOMEXMLMetadata`` API
  ([Java](https://downloads.openmicroscopy.org/bio-formats/5.3.4/api/loci/formats/services/OMEXMLService.html#createOMEXMLMetadata-java.lang.String-)
  /
  [C++](https://downloads.openmicroscopy.org/ome-files-cpp/0.3.1/21/docs/ome-files-bundle-docs-0.3.1-b21/ome-files/api/html/namespaceome_1_1files.html#a469d4ec5c1bddd7b3afc0daa11ba1989))
- metadata.write: the metadata is serialized using the ``getOMEXML``
  API
  ([Java](https://downloads.openmicroscopy.org/bio-formats/5.3.4/api/loci/formats/services/OMEXMLService.html#getOMEXML-loci.formats.meta.MetadataRetrieve-)
  /
  [C++](https://downloads.openmicroscopy.org/ome-files-cpp/0.3.1/21/docs/ome-files-bundle-docs-0.3.1-b21/ome-files/api/html/namespaceome_1_1files.html#ad2898e87098e67fdda2154d7883692e0))
  and written to disk as an OME-XML file
- pixeldata.read: the pixeldata is read from the OME-TIFF using the
  ``openBytes`` API
  ([Java](https://downloads.openmicroscopy.org/bio-formats/5.3.4/api/loci/formats/IFormatReader.html#openBytes-int-byte:A-)
  /
  [C++](https://downloads.openmicroscopy.org/ome-files-cpp/0.3.1/21/docs/ome-files-bundle-docs-0.3.1-b21/ome-files/api/html/classome_1_1files_1_1detail_1_1FormatReader.html#a2106d1dd7b4f4fe6597fde5cdbdb0f37))
  and stored in memory
- pixeldata.write: the pixeldata is written to disk as another
  OME-TIFF using the ``saveBytes`` API
  ([Java](https://downloads.openmicroscopy.org/bio-formats/5.3.4/api/loci/formats/IFormatWriter.html#saveBytes-int-byte:A-)
  /
  [C++](https://downloads.openmicroscopy.org/ome-files-cpp/0.3.1/21/docs/ome-files-bundle-docs-0.3.1-b21/ome-files/api/html/classome_1_1files_1_1detail_1_1FormatWriter.html#a51115641c238f5830f796c1839d75872))

Each benchmark test records the real time in milliseconds before and
after each test, and computes the elapsed time from the difference.

## Benchmark execution

See the top-level [README.md](../README.md) for instructions on how to compile
the performance stack. Before executing the benchmark,:

- the "5D" dataset must be available under a folder called `tubhiswt-4D/tubhiswt_C0_TP0.ome.tif` 
- the "Plate" benchmark `BBBC/NIRHTa-001.ome.tiff` 
- the "ROI" benchmark datasets  `mitocheck/00001_01.ome.tiff`

Then use the `metadata/pixeldata` script. If using Docker execute:

    root@084bb88d5a62:/git/ome-files-performance$ ./scripts/run_benchmarking metadata
    root@084bb88d5a62:/git/ome-files-performance$ ./scripts/run_benchmarking pixeldata

## Benchmark results

The [results](results) folder contains the final set of results
generated using the benchmark tests described above with the following
columns:

- `test.lang`: name of the benchmark environment (Java, C++, Jace)
- `test.name`: name of the benchmark test
- `test.file`: name of the benchmark dataset
- `proc.real`/`real`: execution time measured by the benchmark script

From these tab-separated value files, the following metrics have been defined
for the assessment of each benchmark test:

- performance is defined as the inverse of the execution time for each
  benchmark test
- relative performance of a test is defined as the ratio of the
  performance over the performance of the same test for the same
  dataset executed using Bio-Formats under Linux or Windows, as
  appropriate,
- metadata rate i.e. the rate of XML transfer per unit of time
  expressed in MiB/s is defined as the ratio of the metadata size of
  the test dataset over the execution time of the metadata test,
- pixeldata rate i.e. the rate of binary pixeldata transfer per unit
  of time expressed in MiB/s is defined as the ratio of the the
  pixeldata size of the test dataset over the execution time of the
  pixeldata test.

