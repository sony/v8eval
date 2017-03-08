#!/bin/sh

V8EVAL_ROOT=`cd $(dirname $0)/.. && pwd`

build() {
  cd $V8EVAL_ROOT/ruby
  rake prepare_build
  rake build_ext
}

install() {
  cd $V8EVAL_ROOT
  gem build v8eval.gemspec
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

  gem install bundler -v 1.14.5
  cd $V8EVAL_ROOT/ruby
  bundle install

  rspec --init
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
