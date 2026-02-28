FROM eclipse-temurin:25-jdk-alpine AS builder
COPY build.sh /tmp/build.sh
COPY test.scala /tmp/test.scala
RUN sh /tmp/build.sh

FROM scratch AS export
COPY --from=builder /build /build
