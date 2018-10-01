#!/bin/sh

V8EVAL_ROOT=`cd $(dirname ${0})/.. && pwd`

V8EVAL_INCLUDE_PATH="-I${V8EVAL_ROOT}/v8/include"

V8EVAL_LIBRARY_PATH="-L${V8EVAL_ROOT}/build -L${V8EVAL_ROOT}/v8/out.gn/x64.release/obj"
if [ `uname` = "Linux" ] ; then
  V8EVAL_LIBRARY_PATH="${V8EVAL_LIBRARY_PATH} v8/out.gn/x64.release/obj/buildtools/third_party"
fi

V8EVAL_LIBRARIES="-lv8eval -lv8eval_go -lv8_libplatform -lv8_base -lv8_libbase -lv8_libsampler -lv8_init -lv8_initializers -lv8_nosnapshot -ltorque_generated_initializers"
if [ `uname` = "Linux" ] ; then
  V8EVAL_LIBRARIES="${V8EVAL_LIBRARIES} -ldl -lpthread -lrt -lc++ -lc++abi"
fi

V8EVAL_CFLAGS="-std=c++14"
if [ `uname` = "Linux" ] ; then
  V8EVAL_CFLAGS="${V8EVAL_CFLAGS} -nostdinc++"
  V8EVAL_CFLAGS="${V8EVAL_CFLAGS} -isystem${V8EVAL_ROOT}/v8/buildtools/third_party/libc++/trunk/include"
  V8EVAL_CFLAGS="${V8EVAL_CFLAGS} -isystem${V8EVAL_ROOT}/v8/buildtools/third_party/libc++abi/trunk/include"
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
  "install" ) install ;;
  "test"    ) test ;;
  *         ) echo "unknown subcommand: ${SUBCOMMAND}"; exit 1 ;;
esac
