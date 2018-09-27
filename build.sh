#!/bin/sh

V8EVAL_ROOT=`cd $(dirname ${0}) && pwd`

PLATFORM=`uname`
if [ ${PLATFORM} = "Linux" ]; then
  export CC=${V8EVAL_ROOT}/v8/third_party/llvm-build/Release+Asserts/bin/clang
  export CXX=${V8EVAL_ROOT}/v8/third_party/llvm-build/Release+Asserts/bin/clang++
elif [ ${PLATFORM} = "Darwin" ]; then
  export CC=`which clang`
  export CXX=`which clang++`
  export CPP="`which clang` -E"
  export LINK="`which clang++`"
  export CC_host=`which clang`
  export CXX_host=`which clang++`
  export CPP_host="`which clang` -E"
  export LINK_host=`which clang++`
  export GYP_DEFINES="clang=1 mac_deployment_target=10.10"
else
  echo "unsupported platform: ${PLATFORM}"
  exit 1
fi

install_depot_tools() {
  export PATH=${V8EVAL_ROOT}/depot_tools:${PATH}
  if [ -d ${V8EVAL_ROOT}/depot_tools ]; then
    return 0
  fi

  cd ${V8EVAL_ROOT}
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
}

install_googletest() {
  if [ -d ${V8EVAL_ROOT}/test/googletest ]; then
    return 0
  fi

  cd ${V8EVAL_ROOT}/test
  git clone https://github.com/google/googletest.git
  git checkout release-1.7.0
}

install_v8() {
  if [ -d ${V8EVAL_ROOT}/v8 ]; then
    return 0
  fi

  cd ${V8EVAL_ROOT}
  fetch v8
  cd v8
  git checkout 7.1.177
  gclient sync
  if [ ${PLATFORM} = "Linux" ]; then
    ./build/install-build-deps.sh
  fi
  tools/dev/v8gen.py x64.release
  ninja -C out.gn/x64.release
}

archive_v8_lib() {
  if [ -f ${1}/lib${2}.a ]; then
    return 0
  fi

  ar cr ${1}/lib${2}.a ${1}/${2}/*.o
}

archive_v8() {
  if [ ${PLATFORM} = "Linux" ]; then
    return 0
  fi

  V8_OUT=${V8EVAL_ROOT}/v8/out.gn/x64.release/obj
  archive_v8_lib ${V8_OUT} v8_base
  archive_v8_lib ${V8_OUT} v8_libsampler
  archive_v8_lib ${V8_OUT} v8_init
  archive_v8_lib ${V8_OUT} v8_initializers
  archive_v8_lib ${V8_OUT} v8_nosnapshot
  archive_v8_lib ${V8_OUT} torque_generated_initializers
}

build() {
  install_depot_tools
  install_v8
  archive_v8

  cd ${V8EVAL_ROOT}
  mkdir -p build
  cd build
  cmake -DCMAKE_BUILD_TYPE=Release -DV8EVAL_TEST=OFF ..
  make VERBOSE=1

  cd ${V8EVAL_ROOT}
  rm -rf old_v8_tools_luci-go.git
}

docs() {
  cd ${V8EVAL_ROOT}/docs
  rm -rf ./html
  doxygen
}

test() {
  build
  install_googletest

  cd ${V8EVAL_ROOT}/build
  cmake -DCMAKE_BUILD_TYPE=Release -DV8EVAL_TEST=ON ..
  make VERBOSE=1
  ./test/v8eval-test
}

# dispatch subcommands
SUBCOMMAND=${1}
case ${SUBCOMMAND} in
  ""     ) build ;;
  "docs" ) docs ;;
  "test" ) test ;;
  *      ) echo "unknown subcommand: ${SUBCOMMAND}"; exit 1 ;;
esac
