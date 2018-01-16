FROM ubuntu:16.04
MAINTAINER Olivier Dugas <olivier.dugas@agcocorp.com>

ENV USER builder
ENV HOME /home/builder
ENV SSH_AUTH_SOCK /home/builder/.sockets/ssh

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y -q && apt-get install -y -q --no-install-recommends  \
    autoconf \
    automake \
    autotools-dev \
    bison \
    build-essential \
    ca-certificates \
    ccache \
    cppcheck \
    curl \
    flex \
    g++-5 \
    git-core \
    gperf \
    iproute2 \
    libcap2-bin \
    libdbus-1-dev \
    libfontconfig1-dev \
    libglfw3-dev \
    libpq-dev \
    libssl-dev \
    mesa-common-dev \
    pkg-config \
    qt4-default \
    sudo \
    unzip \
    wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install GoogleTest
ARG GTEST_VERSION="1.8.0"
ARG GTEST_DIR=/home/builder/opt/gtest/googletest
ARG GMOCK_DIR=/home/builder/opt/gtest/googlemock
WORKDIR /home/builder/opt
RUN wget https://github.com/google/googletest/archive/release-${GTEST_VERSION}.zip && \
    unzip release-${GTEST_VERSION}.zip && mv googletest-release-${GTEST_VERSION} gtest && \
    rm release-${GTEST_VERSION}.zip
WORKDIR /home/builder/opt/gtest
RUN g++ -isystem ${GTEST_DIR}/include -I${GTEST_DIR} \
    -isystem ${GMOCK_DIR}/include -I${GMOCK_DIR} \
    -pthread -c ${GTEST_DIR}/src/gtest-all.cc
RUN g++ -isystem ${GTEST_DIR}/include -I${GTEST_DIR} \
    -isystem ${GMOCK_DIR}/include -I${GMOCK_DIR} \
    -pthread -c ${GMOCK_DIR}/src/gmock-all.cc
RUN ar -rv libgmock.a gtest-all.o gmock-all.o && cp libgmock.a ${GMOCK_DIR}
ENV GTEST_DIR=${GTEST_DIR}
ENV GMOCK_DIR=${GMOCK_DIR}
ENV GTEST_ROOT=${GTEST_DIR}
ENV GTEST_LIBRARY=${GTEST_DIR}/../libgmock.a

# Install PROTOBUF
WORKDIR /opt
ARG PROTOBUF_VERSION="3.5.0"
ARG PROTOBUF_TARGET="protobuf-cpp-${PROTOBUF_VERSION}"
RUN wget https://github.com/google/protobuf/releases/download/v${PROTOBUF_VERSION}/${PROTOBUF_TARGET}.tar.gz && \
    tar -xf ${PROTOBUF_TARGET}.tar.gz && rm ${PROTOBUF_TARGET}.tar.gz && \
    cd protobuf-${PROTOBUF_VERSION} && \
    ./configure && make && make install && ldconfig

# Install QT5
WORKDIR /opt
ARG QT_VERSION="5.9.2"
ARG QT_DIR="Qt-${QT_VERSION}"
RUN wget http://download.qt.io/official_releases/qt/5.9/${QT_VERSION}/single/qt-everywhere-opensource-src-${QT_VERSION}.tar.xz && \
    tar -xf qt-everywhere-opensource-src-${QT_VERSION}.tar.xz && \
    rm qt-everywhere-opensource-src-${QT_VERSION}.tar.xz && \
    mkdir ${QT_DIR} && cd ${QT_DIR} && \
    ../qt-every*/configure -opensource -confirm-license -no-use-gold-linker -no-pch -nomake examples -nomake tests \
    -no-glib -no-spellchecker -no-pulseaudio -no-alsa -prefix /opt/${QT_DIR} && \
    make && make install && echo "/opt/${QT_DIR}/lib" >> /etc/ld.so.conf.d/${QT_DIR}.conf

# Allow builder to manipulate network addresses
RUN echo "ALL	ALL=NOPASSWD: /sbin/setcap" >> /etc/sudoers && \
    echo "ALL	ALL=NOPASSWD: /sbin/ip" >> /etc/sudoers && \
    echo "ALL	ALL=NOPASSWD: /sbin/sysctl" >> /etc/sudoers && \
    echo "net.ipv6.conf.all.disable_ipv6 = 0" >> /etc/sysctl.conf
