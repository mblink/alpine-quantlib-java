FROM eclipse-temurin:25-jdk-alpine

COPY build.sh /tmp/build.sh
RUN sh /tmp/build.sh
