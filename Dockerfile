FROM maven:3.9.12-eclipse-temurin-25-alpine AS builder
COPY quantlib-version /tmp/quantlib-version
COPY build.sh /tmp/build.sh
RUN sh /tmp/build.sh

FROM scratch AS export
COPY --from=builder /build /build
