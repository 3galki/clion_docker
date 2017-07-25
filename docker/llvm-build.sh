#!/bin/sh
set -x

MIRROR="https://github.com/llvm-mirror"

WD=${1:-/build}
BRANCH=${2:-master}

git_clone() {
	if [ -n "${2}" ]; then
		tgt=${2}
	else
		tgt=${1}
	fi
	git clone --depth=1 -b ${BRANCH} ${MIRROR}/${1}.git ${tgt} || exit 1
}

# Не больше 8ми потоков в одни руки, а то 32 потока только тормозят друг-друга
pcount=$(grep -c processor /proc/cpuinfo)
if [ "${pcount}" -gt "8" ]; then
	pcount=8
fi
export WIDELANDS_NINJA_THREADS=${pcount}
mkdir -p ${WD}
cd $WD \
	&& git_clone llvm \
	&& cd $WD/llvm/tools \
	&& git_clone clang \
	&& git_clone lld \
	&& git_clone polly \
	&& cd $WD/llvm/tools/clang/tools \
	&& git_clone clang-tools-extra extra \
	 \
	&& cd $WD/llvm/projects \
	&& git_clone compiler-rt \
	&& git_clone openmp \
	&& git_clone libcxx \
	&& git_clone libcxxabi \
	 \
	&& cd $WD \
	&& mkdir build \
	&& cd build \
	 \
	&& cmake3 -G Ninja -DCMAKE_BUILD_TYPE=Release -DLLVM_LIBDIR_SUFFIX=64 $WD/llvm \
	&& ninja -j${pcount} \
	&& cpack3 -G RPM \
	&& mkdir -p /rpm && mv *.rpm /rpm && cd /rpm && rm -rf ${WD} \
	&& yum install local -y /rpm/*.rpm && yum clean all && rm -rf /rpm
cd /
