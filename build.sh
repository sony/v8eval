#!/bin/sh

V8EVAL_ROOT=`cd $(dirname $0) && pwd`

PLATFORM=`uname`
if [ $PLATFORM = "Linux" ]; then
  NUM_CPU_CORES=`cat /proc/cpuinfo | grep cores | grep -o '[0-9]\+' | awk '{total=total+$1}; END{print total}'`

  export CC=$V8EVAL_ROOT/v8/third_party/llvm-build/Release+Asserts/bin/clang
  export CXX=$V8EVAL_ROOT/v8/third_party/llvm-build/Release+Asserts/bin/clang++
elif [ $PLATFORM = "Darwin" ]; then
  NUM_CPU_CORES=`sysctl -n hw.ncpu`

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
  export PATH=$V8EVAL_ROOT/depot_tools:$PATH
  if [ -d $V8EVAL_ROOT/depot_tools ]; then
    return 0
  fi

  cd $V8EVAL_ROOT
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
}

install_googletest() {
  if [ -d $V8EVAL_ROOT/test/googletest ]; then
    return 0
  fi

  cd $V8EVAL_ROOT/test
  git clone https://github.com/google/googletest.git
  git checkout release-1.7.0
}

install_v8() {
  if [ -d $V8EVAL_ROOT/v8 ]; then
    return 0
  fi

  PY_VER=`python -c 'import sys; print(sys.version_info[0])'`
  if [ $PY_VER = 3 ]; then
    OLD_PATH=$PATH
    export PATH=$V8EVAL_ROOT/python/bin:$PATH
  fi

  cd $V8EVAL_ROOT
  fetch v8
  cd v8
  git checkout 5.2.163
  if [ $PY_VER = 3 ]; then
    sed -i -e 's/python -c/python2 -c/' Makefile
  fi
  CFLAGS="-fPIC -Wno-unknown-warning-option" CXXFLAGS="-fPIC -Wno-unknown-warning-option" make x64.release -j$NUM_CPU_CORES V=1

  if [ $PY_VER = 3 ]; then
    export PATH=$OLD_PATH
  fi
}

install_libuv() {
  if [ -d $V8EVAL_ROOT/uv ]; then
    return 0
  fi

  cd $V8EVAL_ROOT
  git clone https://github.com/libuv/libuv.git uv
  cd uv
  git checkout v1.7.5
  sh autogen.sh
  ./configure --with-pic --disable-shared
  make V=1
}

build() {
  install_depot_tools
  install_v8
  install_libuv

  cd $V8EVAL_ROOT
  mkdir -p build
  cd build
  cmake -DCMAKE_BUILD_TYPE=Release -DV8EVAL_TEST=OFF ..
  make VERBOSE=1
}

docs() {
  cd $V8EVAL_ROOT/docs
  rm -rf ./html
  doxygen
}

test() {
  build
  install_googletest

  cd $V8EVAL_ROOT/build
  cmake -DCMAKE_BUILD_TYPE=Release -DV8EVAL_TEST=ON ..
  make VERBOSE=1
  ./test/v8eval-test
}

# dispatch subcommand
SUBCOMMAND="$1";
case "${SUBCOMMAND}" in
  ""       ) build ;;
  "docs"   ) docs ;;
  "test"   ) test ;;
  *        ) echo "unknown subcommand: ${SUBCOMMAND}"; exit 1 ;;
esac
