# clion-docker
Скрипты для сборки проктов из CLion через docker

Cборка образа для docker командой:

docker build --build-arg LLVM_VERSION=branches/release_39 --build-arg CLANG_VERSION=3.9 -t clang-conan:3.9 .

