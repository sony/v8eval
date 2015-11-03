#!/bin/sh

V8EVAL_ROOT=`cd $(dirname $0)/.. && pwd`

build() {
  cd $V8EVAL_ROOT/ruby && rake prepare_build
  cd $V8EVAL_ROOT && gem build v8eval.gemspec
}

install() {
  cd $V8EVAL_ROOT
  gem install v8eval-*.gem
}

docs() {
  cd $V8EVAL_ROOT/ruby
  rm -rf ./doc
  mkdir ./doc
  yardoc --main ../README.md lib/v8eval.rb
}

test() {
  build

  gem install bundle
  cd $V8EVAL_ROOT/ruby
  bundle install

  rspec --init
  rake build_ext
  rspec
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
