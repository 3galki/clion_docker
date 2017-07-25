FROM gitlab-dev.ispsystem.net:5005/docker/conan-base:latest
LABEL maintainer "tuupic@ispsystem.com"
ENV BUILD_DIR="/build"
RUN yum -y install gcc-c++ rpm-build && yum clean all && mkdir $BUILD_DIR

COPY conan/settings.yml conan/conan.conf /root/.conan/
ARG CLANG_VERSION=4.0
RUN echo "compiler.version=$CLANG_VERSION" >> /root/.conan/conan.conf && cat /root/.conan/conan.conf

# install clang
COPY llvm-build.sh $BUILD_DIR/
ARG LLVM_VERSION=RELEASE_40
RUN $BUILD_DIR/llvm-build.sh $BUILD_DIR $LLVM_VERSION && ln -s ../../bin/ccache /usr/lib64/ccache/clang++ && ln -s ../../bin/ccache /usr/lib64/ccache/clang && rm -rf $BUILD_DIR
ENV CC="clang" CXX="clang++"
