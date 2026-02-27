FROM alpine:3.23

ENV BOOST_VERSION=1.90.0
ENV QUANTLIB_VERSION=1.41

RUN apk add --no-cache --update --virtual .build-dependencies automake autoconf build-base libtool linux-headers && \
  mkdir -p /tmp/build && \
  cd /tmp/build && \
  BOOST_DIR="boost_$(echo $BOOST_VERSION | tr '.' '_')" && \
  CPUS="$(nproc --all)" && \
  wget "https://archives.boost.io/release/${BOOST_VERSION}/source/${BOOST_DIR}.tar.gz" && \
  tar -xzf "${BOOST_DIR}.tar.gz" && \
  cd "${BOOST_DIR}" && \
  ./bootstrap.sh && \
  ./b2 --without-python --prefix=/usr -j "$CPUS" link=shared runtime-link=shared install && \
  cd .. && \
  wget "https://github.com/lballabio/QuantLib/releases/download/v${QUANTLIB_VERSION}/QuantLib-${QUANTLIB_VERSION}.tar.gz" && \
  tar -xzf "QuantLib-${QUANTLIB_VERSION}.tar.gz" && \
  cd "QuantLib-${QUANTLIB_VERSION}" && \
  sh autogen.sh && \
  ./configure --prefix=/usr --disable-static --disable-examples --disable-benchmark CXXFLAGS=-O3 && \
  make -j "$CPUS" && \
  make install && \
  ldconfig ./ && \
  cd .. && \
  rm -rf /tmp/build && \
  apk del .build-dependencies

CMD ["sh"]
