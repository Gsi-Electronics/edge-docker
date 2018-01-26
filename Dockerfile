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
    cmake \
    cppcheck \
    curl \
    flex \
    g++-5 \
    gdbserver \
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
    python-setuptools \
    qt4-default \
    sudo \
    unzip \
    wget \
    xsltproc && \
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
    ./configure && make && make install && ldconfig && \
    cd .. && rm -rf protobuf-${PROTOBUF_VERSION}

# Install six (dependency for python-protobuf
WORKDIR /opt
ARG SIX_VERSION="1.11.0"
RUN wget https://pypi.python.org/packages/16/d8/bc6316cf98419719bd59c91742194c111b6f2e85abac88e496adefaf7afe/six-1.11.0.tar.gz#md5=d12789f9baf7e9fb2524c0c64f1773f8 && \
    tar -xzvf six-${SIX_VERSION}.tar.gz && rm six-${SIX_VERSION}.tar.gz && \
    cd six-${SIX_VERSION} && \
    python setup.py build && python setup.py install && \
    cd .. && rm -rf six-${SIX_VERSION}

# Install python-protobuf
WORKDIR /opt
ARG PROTOBUF_TARGET="protobuf-python-${PROTOBUF_VERSION}"
RUN wget https://github.com/google/protobuf/releases/download/v${PROTOBUF_VERSION}/${PROTOBUF_TARGET}.tar.gz && \
    tar -xzvf ${PROTOBUF_TARGET}.tar.gz && rm ${PROTOBUF_TARGET}.tar.gz && \
    cd protobuf-${PROTOBUF_VERSION}/python && \
    python setup.py build && python setup.py install && \
    cd ../.. && rm -rf protobuf-${PROTOBUF_VERSION}

# Install nanopb
WORKDIR /opt
ARG NANOPB_VERSION="0.3.9"
RUN wget https://github.com/nanopb/nanopb/archive/${NANOPB_VERSION}.tar.gz && \
    tar -xzvf ${NANOPB_VERSION}.tar.gz && rm ${NANOPB_VERSION}.tar.gz && \
    cd nanopb-${NANOPB_VERSION}/generator/proto && make

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
    make && make install && echo "/opt/${QT_DIR}/lib" >> /etc/ld.so.conf.d/${QT_DIR}.conf && \
    rm -rf /opt/qt-everywhere*

# Install Boost
WORKDIR /opt
ARG BOOST_TARBALL="boostx86.tgz"
ARG INTERNAL_FILESERVER="10.51.208.171"
RUN wget ${INTERNAL_FILESERVER}/docker/${BOOST_TARBALL} && \
    tar -xzvf ${BOOST_TARBALL} && rm ${BOOST_TARBALL} && \
    echo "/opt/boost-1.65.1/lib" >> /etc/ld.so.conf.d/boost-1.65.1.conf

# Install nanomsg
WORKDIR /opt
ARG NANOMSG_VERSION="1.0.0"
ARG NANOMSG_TARGET="nanomsg-${NANOMSG_VERSION}"
RUN wget https://github.com/nanomsg/nanomsg/archive/${NANOMSG_VERSION}.tar.gz && \
    tar -xf ${NANOMSG_VERSION}.tar.gz && rm ${NANOMSG_VERSION}.tar.gz && \
    mkdir ${NANOMSG_TARGET}/build && cd ${NANOMSG_TARGET}/build && \
    cmake .. && cmake --build . && cmake --build . --target install && ldconfig && \
    cd ../.. && rm -rf ${NANOMSG_TARGET}

# Install unittest-cpp
ARG UNITTESTPP_VERSION="2.0.0"
WORKDIR /opt
RUN git clone https://github.com/unittest-cpp/unittest-cpp && \
    cd unittest-cpp/builds && git checkout v${UNITTESTPP_VERSION} && \
    cmake -DCMAKE_INSTALL_PREFIX=/opt/unittest-cpp-${UNITTESTPP_VERSION} .. && \
    make && make install && ldconfig && \
    cd ../.. && rm -rf unittest-cpp

# Allow builder to manipulate network addresses
RUN echo "ALL	ALL=NOPASSWD: /sbin/setcap" >> /etc/sudoers && \
    echo "ALL	ALL=NOPASSWD: /sbin/ip" >> /etc/sudoers && \
    echo "ALL	ALL=NOPASSWD: /sbin/sysctl" >> /etc/sudoers && \
    echo "net.ipv6.conf.all.disable_ipv6 = 0" >> /etc/sysctl.conf
