
ARG VERILATOR_VERSION=5.034
ARG UBUNTU_VERSION=24.04

FROM ubuntu:${UBUNTU_VERSION} AS builder

RUN apt-get update && apt-get install -y curl build-essential

# apt update and upgrade
RUN apt-get update && apt-get install -y lsb-release wget software-properties-common gnupg curl && \
    curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | apt-key add && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    build-essential \
    device-tree-compiler \
    git \
    gnupg2 \
    lsb-release \
    software-properties-common \
    tar \
    unzip \
    wget \
    zlib1g-dev \
    zsh \
    vim \
    nano \
    python3 \
    help2man perl make autoconf g++ flex bison ccache \
    libgoogle-perftools-dev numactl perl-doc \
    libfl2 libfl-dev zlib1g zlib1g-dev \
    python3-pip && \
    python3 -m pip config set global.break-system-packages true

# Install Verilator
RUN git clone https://github.com/verilator/verilator && \
    cd verilator && \
    git checkout v${VERILATOR_VERSION} && \
    unset VERILATOR_ROOT && \
    autoconf && \
    ./configure && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    rm -rf verilator && \
    rm -rf /root/.cache

ENV VLT_ROOT=/usr/local/share/verilator