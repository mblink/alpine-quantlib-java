#!/usr/bin/env sh

set -exo pipefail

export CPUS="$(nproc)"
export BOOST_VERSION=1.90.0
export MAVEN_VERSION=3.9.12
export QUANTLIB_VERSION=1.41.0
export QUANTLIB_JAR_VERSION=0.1.0-SNAPSHOT
export SWIG_VERSION=4.4.1

apk add --no-cache --update --virtual .build-dependencies \
  automake autoconf bison build-base cmake git libtool linux-headers ninja-build pcre2-dev

export PATH="$PATH:/usr/lib/ninja-build/bin"

export BUILD_DIR="/tmp/build"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Build boost
BOOST_DIR="boost-$BOOST_VERSION"
wget "https://github.com/boostorg/boost/releases/download/boost-$BOOST_VERSION/$BOOST_DIR-b2-nodocs.tar.xz"
tar -xf "$BOOST_DIR-b2-nodocs.tar.xz"
cd "$BOOST_DIR"
./bootstrap.sh
./b2 --without-python --prefix=/usr -j "$CPUS" link=shared runtime-link=shared install
cd "$BUILD_DIR"

# Build swig
SWIG_DIR="swig-$SWIG_VERSION"
wget "https://github.com/swig/swig/archive/refs/tags/v$SWIG_VERSION.tar.gz" -O "$SWIG_DIR.tar.gz"
tar -xzf "$SWIG_DIR.tar.gz"
cd "$SWIG_DIR"
./autogen.sh
./configure --prefix=/usr
make -j "$CPUS"
make install
cd "$BUILD_DIR"

# Install maven
MAVEN_DIR="apache-maven-$MAVEN_VERSION"
wget "https://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/$MAVEN_DIR-bin.tar.gz"
tar -xzf "$MAVEN_DIR-bin.tar.gz"
ln -s "$MAVEN_DIR/bin/mvn /usr/bin/mvn"

# Build quantlib_for_maven
git clone --revision "v$QUANTLIB_VERSION" --recurse-submodules --jobs "$CPUS" https://github.com/ralfkonrad/quantlib_for_maven.git
cd quantlib_for_maven
cmake --preset release -L
cmake --build --preset release -v --parallel "$CPUS"
cd java
./mvnw install
mkdir /build
MAVEN_PREFIX="/root/.m2/repository/io/github/ralfkonrad/quantlib_for_maven/quantlib/$QUANTLIB_JAR_VERSION/quantlib-$QUANTLIB_JAR_VERSION"
mv "$MAVEN_PREFIX.jar" "$MAVEN_PREFIX.pom" /build/

# Clean up
cd
rm -rf "$BUILD_DIR"
apk del .build-dependencies
