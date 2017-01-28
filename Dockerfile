FROM ubuntu:16.04
MAINTAINER ome-devel@lists.openmicroscopy.org.uk

RUN apt-get update && apt-get -y install \
  build-essential \
  cmake \
  git \
  libboost-all-dev \
  libxerces-c-dev \
  libxalan-c-dev \
  libpng-dev \
  libgtest-dev \
  libtiff5-dev \
  python-pip
RUN pip install Genshi

WORKDIR /git
RUN git clone --branch='v0.2.3' https://github.com/ome/ome-cmake-superbuild.git

WORKDIR /build
RUN cmake \
    -Dgit-dir=/git \
    -Dbuild-prerequisites=OFF \
    -Dome-superbuild_BUILD_gtest=ON \
    -Dbuild-packages=ome-files \
    /git/ome-cmake-superbuild
RUN make
RUN make install
RUN ldconfig

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
RUN apt-get update && apt-get -y install \
  default-jdk \
  maven
RUN mvn clean install

CMD ["/bin/bash"]
