FROM sbesson/ome-files-cpp-u1604
MAINTAINER ome-devel@lists.openmicroscopy.org.uk

# Install JDK7 and Maven
RUN apt-get -y install software-properties-common
RUN add-apt-repository ppa:openjdk-r/ppa
RUN apt-get update
RUN apt-get -y install openjdk-7-jdk openjdk-7-jre-lib
RUN apt-get -y install maven
ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64

#  Bio-Formats JACE bindings
RUN git clone https://github.com/ome/bio-formats-jace /git/bio-formats-jace
WORKDIR /git/bio-formats-jace
# Workaround for versions
RUN sed -i -e "s/5.2.1/5.2.4/g" pom.xml
RUN mvn -DskipTests clean package cppwrap:wrap dependency:copy-dependencies

COPY cmake/JACEPrerequisites.cmake /git/bio-formats-jace/target/cppwrap

# Build JACE performance component
WORKDIR /build-jace
RUN cmake -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH=$OME_FILES_BUNDLE \
  -DCMAKE_PROGRAM_PATH=$OME_FILES_BUNDLE/bin \
  -DCMAKE_LIBRARY_PATH=$OME_FILES_BUNDLE/lib \
  /git/bio-formats-jace/target/cppwrap
RUN cmake --build .
ENV BF_JACE_HOME /build-jace/dist/bio-formats-jace

# Build OME Files performance component
COPY . /git/ome-files-performance

WORKDIR /build-ome-files
RUN cmake -DCMAKE_INSTALL_PREFIX:PATH=/install \
  -DCMAKE_CXX_STANDARD=11 \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="$OME_FILES_BUNDLE;$BF_JACE_HOME" \
  -DCMAKE_PROGRAM_PATH=$OME_FILES_BUNDLE/bin \
  -DCMAKE_LIBRARY_PATH=$OME_FILES_BUNDLE/lib \
  /git/ome-files-performance
RUN cmake --build .
RUN cmake --build . --target install

# Builf Bio-Formats performance component
WORKDIR /git/ome-files-performance
RUN mvn clean install

ENV LD_LIBRARY_PATH $BF_JACE_HOME:$JAVA_HOME/jre/lib/amd64/server
ENTRYPOINT ["/bin/bash", "/git/ome-files-performance/scripts/run_benchmarking"]
