# extconf.rb
require 'rbconfig'
require 'mkmf'
require_relative '../../lib/setup/extension_builder'

# set path variables
v8eval_root = File.expand_path('../../..', Dir.pwd)
v8_dir = v8eval_root + '/v8'
uv_dir = v8eval_root + '/uv'

# make instance of BuildTool class
tool = BuildTool.new(v8eval_root)

# install v8 and build libv8eval.a
tool.install_v8

# generate v8eval_wrap.cxx
tool.run_swig

LIBDIR      = RbConfig::CONFIG['libdir']
INCLUDEDIR  = RbConfig::CONFIG['includedir']

header_dirs = [
  v8_dir,
  v8_dir + '/include',
  uv_dir + '/include',
  INCLUDEDIR
]

lib_dirs = [
  v8eval_root + '/build',
  uv_dir + '/.libs',
  LIBDIR
]

if RUBY_PLATFORM =~ /darwin/
  lib_dirs += [
    v8_dir + '/out/x64.release'
  ]
elsif RUBY_PLATFORM =~ /linux/
  lib_dirs += [
    v8_dir + '/out/x64.release/obj.target/src'
  ]

  RbConfig::MAKEFILE_CONFIG['CC'] = v8_dir + '/third_party/llvm-build/Release+Asserts/bin/clang'
  RbConfig::MAKEFILE_CONFIG['CXX'] = v8_dir + '/third_party/llvm-build/Release+Asserts/bin/clang++'
end

dir_config('', header_dirs, lib_dirs)

$LDFLAGS << ' -lv8eval -lv8eval_ruby -lv8_libplatform -lv8_base -lv8_libbase -lv8_libsampler -lv8_init -lv8_initializers -lv8_nosnapshot -luv'
$CPPFLAGS << ' -g -O3 -std=c++11'

create_makefile('v8eval/v8eval')
