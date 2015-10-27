#!/bin/sh

V8EVAL_ROOT=`cd $(dirname $0)/.. && pwd`

V8EVAL_INCLUDE_PATH="-I$V8EVAL_ROOT/v8/include"

V8EVAL_LIBRARY_PATH="-L$V8EVAL_ROOT/build"
if [ `uname` = "Darwin" ]; then
  V8EVAL_LIBRARY_PATH="$V8EVAL_LIBRARY_PATH -L$V8EVAL_ROOT/v8/out/x64.release"
else
  V8EVAL_LIBRARY_PATH="$V8EVAL_LIBRARY_PATH -L$V8EVAL_ROOT/v8/out/x64.release/obj.target/tools/gyp -L$V8EVAL_ROOT/v8/out/x64.release/obj.target/third_party/icu"
fi
V8EVAL_LIBRARY_PATH="$V8EVAL_LIBRARY_PATH -L$V8EVAL_ROOT/uv/.libs"

V8EVAL_LIBRARIES="-lv8eval -lv8_libplatform -lv8_base -lv8_libbase -lv8_nosnapshot -licui18n -licuuc -licudata -luv"
if [ `uname` = "Linux" ] ; then
  V8EVAL_LIBRARIES="$V8EVAL_LIBRARIES -ldl -lpthread"
fi

CGO_FLAGS="// #cgo CXXFLAGS: -g -O2 -std=c++11 $V8EVAL_INCLUDE_PATH\n// #cgo LDFLAGS: $V8EVAL_LIBRARY_PATH $V8EVAL_LIBRARIES"

build() {
  $V8EVAL_ROOT/build.sh

  cd $V8EVAL_ROOT/go/v8eval
  cp $V8EVAL_ROOT/src/v8eval.h .
  swig -c++ -go -intgosize 64 -cgo -outdir . -o ./v8eval_wrap.cxx $V8EVAL_ROOT/src/v8eval.i
  perl -i -l -p -e "print \"$CGO_FLAGS\" if(/^import \"C\"$/);" ./v8eval.go
  go build -x .
}

install() {
  build

  cd $V8EVAL_ROOT/go/v8eval
  go install -x .
}

test() {
  build
  go get github.com/stretchr/testify/assert

  cd $V8EVAL_ROOT/go/v8eval
  go test
}

# dispatch subcommand
SUBCOMMAND="$1";
case "${SUBCOMMAND}" in
  ""        ) build ;;
  "install" ) install ;;
  "test"    ) test ;;
  *         ) echo "unknown subcommand: ${SUBCOMMAND}"; exit 1 ;;
esac
