FROM openmicroscopy/ome-files-cpp-u1604
MAINTAINER ome-devel@lists.openmicroscopy.org.uk

RUN apt-get update && apt-get -y install \
  default-jdk \
  maven

ADD . /git/ome-files-performance

WORKDIR /build2
RUN cmake -DCMAKE_INSTALL_PREFIX:PATH=/install \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH=$OME_FILES_BUNDLE \
  -DCMAKE_PROGRAM_PATH=$OME_FILES_BUNDLE/bin \
  -DCMAKE_LIBRARY_PATH=$OME_FILES_BUNDLE/lib \
  /git/ome-files-performance
RUN cmake --build .
RUN cmake --build . --target install

WORKDIR /git/ome-files-performance
RUN mvn clean install

ENTRYPOINT ["/bin/bash", "/git/ome-files-performance/scripts/run_benchmarking"]
