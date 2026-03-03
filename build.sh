#!/usr/bin/env sh

set -exo pipefail

export CPUS="$(nproc)"
export BOOST_VERSION=1.84.0
export QUANTLIB_VERSION="$(cat /tmp/quantlib-version)"
unset MAVEN_CONFIG

apk add --no-cache --update --virtual .build-dependencies "boost${BOOST_VERSION%.*}-dev" build-base cmake git ninja-build swig

export PATH="$PATH:/usr/lib/ninja-build/bin"
export SWIG_VERSION_REGEX='^SWIG Version (.*)$'
export SWIG_VERSION="$(swig --version | grep -E "$SWIG_VERSION_REGEX" | sed -E "s/$SWIG_VERSION_REGEX/\1/")"

cd /tmp

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
cmake --preset release -DQL_MVN_BOOST_VERSION="$BOOST_VERSION" -DQL_MVN_SWIG_VERSION="$SWIG_VERSION" -L
cmake --build --preset release -v --parallel "$CPUS"
cd java
./mvnw install
mkdir /build
MAVEN_PREFIX="/root/.m2/repository/io/github/ralfkonrad/quantlib_for_maven/quantlib/$QUANTLIB_VERSION/quantlib-$QUANTLIB_VERSION"
mv "$MAVEN_PREFIX.jar" "$MAVEN_PREFIX.pom" /build/

# Clean up
cd
rm -rf /tmp/quantlib_for_maven
apk del .build-dependencies
