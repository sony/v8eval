#!/bin/sh

V8EVAL_ROOT=`cd $(dirname ${0})/.. && pwd`

V8EVAL_INCLUDE_PATH="-I${V8EVAL_ROOT}/v8/include"

V8_OUT=${V8EVAL_ROOT}/v8/out.gn/x64.release/obj
V8EVAL_LIBRARY_PATH="-L${V8EVAL_ROOT}/build -L${V8_OUT}"
if [ `uname` = "Linux" ] ; then
  V8EVAL_LIBRARY_PATH="${V8EVAL_LIBRARY_PATH} -L${V8_OUT}/buildtools/third_party/libc++"
  V8EVAL_LIBRARY_PATH="${V8EVAL_LIBRARY_PATH} -L${V8_OUT}/buildtools/third_party/libc++abi"
fi

V8EVAL_LIBRARIES="-lv8eval_go -lv8eval -lv8_libplatform -lv8_base -lv8_libbase -lv8_libsampler -lv8_init -lv8_initializers -lv8_nosnapshot -ltorque_generated_initializers"
if [ `uname` = "Linux" ] ; then
  V8EVAL_LIBRARIES="${V8EVAL_LIBRARIES} -ldl -lpthread -lrt -lc++ -lc++abi"
fi

V8EVAL_CFLAGS="-std=c++14"
if [ `uname` = "Linux" ] ; then
  V8EVAL_CFLAGS="${V8EVAL_CFLAGS} -isystem ${V8EVAL_ROOT}/v8/buildtools/third_party/libc++/trunk/include"
  V8EVAL_CFLAGS="${V8EVAL_CFLAGS} -isystem ${V8EVAL_ROOT}/v8/buildtools/third_party/libc++abi/trunk/include"
fi

export CC=${V8EVAL_ROOT}/v8/third_party/llvm-build/Release+Asserts/bin/clang
export CXX=${V8EVAL_ROOT}/v8/third_party/llvm-build/Release+Asserts/bin/clang++
if [ `uname` = "Linux" ] ; then
  export CXX="${CXX} -nostdinc++"
  export PATH=${V8EVAL_ROOT}/v8/third_party/binutils/Linux_x64/Release/bin:${PATH}
fi

CGO_FLAGS="// #cgo CXXFLAGS: ${V8EVAL_CFLAGS} ${V8EVAL_INCLUDE_PATH}\n// #cgo LDFLAGS: ${V8EVAL_LIBRARY_PATH} ${V8EVAL_LIBRARIES}"

build() {
  ${V8EVAL_ROOT}/build.sh

  cd ${V8EVAL_ROOT}/go/v8eval
  cp ${V8EVAL_ROOT}/src/v8eval.h .
  cp ${V8EVAL_ROOT}/src/v8eval_go.h .
  swig -c++ -go -intgosize 64 -cgo -outdir . -o ./v8eval_wrap.cxx v8eval.i
  perl -i -l -p -e "print \"${CGO_FLAGS}\" if(/^import \"C\"$/);" ./v8eval.go
  go build -x .
}

install() {
  build

  cd ${V8EVAL_ROOT}/go/v8eval
  go install -x .
}

test() {
  build
  go get github.com/stretchr/testify/assert

  cd ${V8EVAL_ROOT}/go/v8eval
  go test
}

# dispatch subcommand
SUBCOMMAND=${1};
case ${SUBCOMMAND} in
  ""        ) build ;;
  "go"      ) shift; go ${@} ;;
  "install" ) install ;;
  "test"    ) test ;;
  *         ) echo "unknown subcommand: ${SUBCOMMAND}"; exit 1 ;;
esac
