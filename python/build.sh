#!/bin/sh

V8EVAL_ROOT=`cd $(dirname $0)/.. && pwd`

build() {
  cd $V8EVAL_ROOT
  python setup.py build_ext --inplace
}

install() {
  cd $V8EVAL_ROOT
  pip install --upgrade .
}

docs() {
  build

  cd $V8EVAL_ROOT/python
  rm -rf ./docs
  mkdir ./docs
  cd ./docs
  export LC_ALL=en_US.UTF-8
  export LANG=en_US.UTF-8
  export PYTHONPATH=$V8EVAL_ROOT/python/v8eval
  sphinx-quickstart -q -p v8eval -a 'Yoshiyuki Mineo' -v 0.1 -r 0.2.5 --ext-autodoc --ext-viewcode
  sphinx-apidoc -M -o . ../v8eval
  perl -ni -e 'die if /Submodules/; print' ./v8eval.rst
  perl -pi -e 'print ":orphan:\n\n" if $. == 1' ./modules.rst
  make html
}

test() {
  build

  export PYTHONPATH=$V8EVAL_ROOT/python/v8eval:$V8EVAL_ROOT/python/test
  python -m unittest test_v8eval
}

# dispatch subcommand
SUBCOMMAND="$1";
case "${SUBCOMMAND}" in
  ""        ) build ;;
  "install" ) install ;;
  "docs"    ) docs ;;
  "test"    ) test ;;
  *         ) echo "unknown subcommand: ${SUBCOMMAND}"; exit 1 ;;
esac
