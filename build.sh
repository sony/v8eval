#!/bin/sh

V8EVAL_ROOT=`cd $(dirname ${0}) && pwd`

PLATFORM=`uname`
if [ ! ${PLATFORM} = "Linux" -a ! ${PLATFORM} = "Darwin" ]; then
  echo "unsupported platform: ${PLATFORM}"
  exit 1
fi

export CC=${V8EVAL_ROOT}/v8/third_party/llvm-build/Release+Asserts/bin/clang
export CXX=${V8EVAL_ROOT}/v8/third_party/llvm-build/Release+Asserts/bin/clang++

if [ ${PLATFORM} = "Linux" ]; then
  export PATH=${V8EVAL_ROOT}/v8/third_party/binutils/Linux_x64/Release/bin:${PATH}
fi

install_depot_tools() {
  export PATH=${V8EVAL_ROOT}/depot_tools:${PATH}
  if [ -d ${V8EVAL_ROOT}/depot_tools ]; then
    return 0
  fi

  cd ${V8EVAL_ROOT}
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
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
  tools/dev/v8gen.py x64.release -- v8_use_snapshot=false v8_enable_i18n_support=false
  ninja -v -C out.gn/x64.release
}

archive_lib() {
  if [ -f ${1}/lib${2}.a ]; then
    return 0
  fi

  if [ `echo ${2} | cut -c 1-3` = "lib" ]; then
    ar cr ${1}/${2}.a ${1}/${2}/*.o
  else
    ar cr ${1}/lib${2}.a ${1}/${2}/*.o
  fi
}

V8_OUT=${V8EVAL_ROOT}/v8/out.gn/x64.release/obj

archive_v8() {
  archive_lib ${V8_OUT} v8_base
  archive_lib ${V8_OUT} v8_libsampler
  archive_lib ${V8_OUT} v8_init
  archive_lib ${V8_OUT} v8_initializers
  archive_lib ${V8_OUT} v8_nosnapshot
  archive_lib ${V8_OUT} torque_generated_initializers
}

archive_libcxx() {
  archive_lib ${V8_OUT}/buildtools/third_party/libc++ libc++
}

archive_libcxxabi() {
  archive_lib ${V8_OUT}/buildtools/third_party/libc++abi libc++abi
}

archive_googletest() {
  archive_lib ${V8_OUT}/third_party/googletest gtest
  archive_lib ${V8_OUT}/third_party/googletest gtest_main
}

build() {
  install_depot_tools
  install_v8
  archive_v8
  if [ ${PLATFORM} = "Linux" ]; then
    archive_libcxx
    archive_libcxxabi
  fi

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
  archive_googletest

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
