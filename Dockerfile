FROM eclipse-temurin:25-jdk-alpine

ENV BOOST_VERSION=1.90.0
ENV MAVEN_VERSION=3.9.12
ENV QUANTLIB_VERSION=1.41.0
ENV SWIG_VERSION=4.4.1

RUN apk add --no-cache --update --virtual .build-dependencies automake autoconf bison build-base cmake git libtool linux-headers ninja-build pcre2-dev && \
  mkdir -p /tmp/build && \
  cd /tmp/build && \
  CPUS="$(nproc)" && \
  export PATH="$PATH:/usr/lib/ninja-build/bin" && \
  # Build boost
  BOOST_DIR="boost-${BOOST_VERSION}" && \
  wget "https://github.com/boostorg/boost/releases/download/boost-${BOOST_VERSION}/${BOOST_DIR}-b2-nodocs.tar.xz" && \
  tar -xf "${BOOST_DIR}-b2-nodocs.tar.xz" && \
  cd "${BOOST_DIR}" && \
  ./bootstrap.sh && \
  ./b2 --without-python --prefix=/usr -j "$CPUS" link=shared runtime-link=shared install && \
  cd .. && \
  # Build swig
  SWIG_DIR="swig-${SWIG_VERSION}" && \
  wget "https://github.com/swig/swig/archive/refs/tags/v${SWIG_VERSION}.tar.gz" -O "${SWIG_DIR}.tar.gz" && \
  tar -xzf "${SWIG_DIR}.tar.gz" && \
  cd "${SWIG_DIR}" && \
  ./autogen.sh && \
  ./configure --prefix=/usr && \
  make -j "$CPUS" && \
  make install && \
  cd .. && \
  # Install maven
  MAVEN_DIR="apache-maven-${MAVEN_VERSION}" && \
  wget "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/${MAVEN_DIR}-bin.tar.gz" && \
  tar -xzf "${MAVEN_DIR}-bin.tar.gz" && \
  ln -s "${MAVEN_DIR}/bin/mvn /usr/bin/mvn" && \
  # Build quantlib_for_maven
  git clone --revision "v${QUANTLIB_VERSION}" --recurse-submodules --jobs "$CPUS" https://github.com/ralfkonrad/quantlib_for_maven.git && \
  cd quantlib_for_maven && \
  cmake --preset release -L && \
  cmake --build --preset release -v --parallel "$CPUS" && \
  mkdir /build && \
  mv java/target/* /build/ && \
  cd .. && \
  # Clean up
  rm -rf /tmp/build && \
  apk del .build-dependencies
