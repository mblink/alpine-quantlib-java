#!/usr/bin/env sh

set -exo pipefail

export CPUS="$(nproc)"
export BOOST_VERSION=1.90.0
export MAVEN_VERSION=3.9.12
export QUANTLIB_VERSION="$(cat /tmp/quantlib-version)"
export SWIG_VERSION=4.4.1

apk add --no-cache --update --virtual .build-dependencies \
  automake autoconf bison build-base cmake curl git jq libtool linux-headers ninja-build pcre2-dev

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
echo "diff --git a/java/pom.xml b/java/pom.xml
index 68ecd0e..626616b 100644
--- a/java/pom.xml
+++ b/java/pom.xml
@@ -5,7 +5,7 @@

     <groupId>io.github.ralfkonrad.quantlib_for_maven</groupId>
     <artifactId>quantlib</artifactId>
-    <version>0.1.0-SNAPSHOT</version>
+    <version>$QUANTLIB_VERSION</version>
     <packaging>jar</packaging>

     <name>QuantLib module</name>
" | git apply
cmake --preset release -L
cmake --build --preset release -v --parallel "$CPUS"
cd java
./mvnw install
mkdir /build
MAVEN_PREFIX="/root/.m2/repository/io/github/ralfkonrad/quantlib_for_maven/quantlib/$QUANTLIB_VERSION/quantlib-$QUANTLIB_VERSION"
mv "$MAVEN_PREFIX.jar" "$MAVEN_PREFIX.pom" /build/

# Install scala-cli
scalaCliJar="$BUILD_DIR/scala-cli.jar"
scalaCliVersion="$(curl -s 'https://api.github.com/repos/VirtusLab/scala-cli/releases/latest' | jq -r '.tag_name' | sed -E 's/^v?//')"
curl -o "$scalaCliJar" "https://repo1.maven.org/maven2/org/virtuslab/scala-cli/cliBootstrapped/$scalaCliVersion/cliBootstrapped-$scalaCliVersion.jar"

# Test quantlib jar with scala-cli
java -jar "$scalaCliJar" \
  --server=false \
  -S 3.8.2 \
  --classpath "/build/quantlib-$QUANTLIB_VERSION.jar" \
  --dep org.slf4j:slf4j-api:2.0.17 \
  /tmp/test.scala

# Clean up
cd
rm -rf "$BUILD_DIR"
apk del .build-dependencies
