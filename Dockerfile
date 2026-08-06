FROM ubuntu:20.04
LABEL maintainer="Alex Sickler (asickler@childrensnational.org)"

ARG DEBIAN_FRONTEND=noninteractive

ENV GOSSAMER_HASH=324a75805b51eb7e4773c7e9079dc2ecc2cd91db

RUN apt-get update && apt-get install -y \
    g++ \
    cmake \
    libboost-all-dev \
    pandoc \
    zlib1g-dev \
    libbz2-dev \
    libsqlite3-dev \
    git \
    pigz

RUN git clone https://github.com/data61/gossamer && \
    cd gossamer && \
    git checkout "$GOSSAMER_HASH" && \
    mkdir build && \
    cd build && \
    cmake -Wno-dev \
        -DCMAKE_CXX_FLAGS="-DBOOST_TIMER_ENABLE_DEPRECATED" \
        -DBUILD_tests=OFF .. && \
    make && \
    make install

ADD Dockerfile .