#!/usr/bin/env python

from distutils.core import setup, Extension
from os import system
from os.path import abspath, dirname, exists
from sys import platform


# set path variables
v8eval_root = abspath(dirname(__file__))
v8_dir = v8eval_root + "/v8"
uv_dir = v8eval_root + "/uv"
py_dir = v8eval_root + "/python"
py_v8eval_dir = py_dir + "/v8eval"


# install v8 and build libv8eval.a
system(v8eval_root + "/build.sh")


# generate v8eval_wrap.cxx and v8eval.py
system("cp " + v8eval_root + "/src/v8eval.h " + py_v8eval_dir)
system("swig -c++ -python -outdir " + py_v8eval_dir + " -o "  + py_v8eval_dir + "/v8eval_wrap.cxx " + v8eval_root + "/src/v8eval.i")
system("cat " + py_dir + "/_v8eval.py >> " + py_v8eval_dir + "/v8eval.py")


# build _v8eval.so
include_dirs = [v8_dir, v8_dir + '/include', uv_dir + '/include']

library_dirs = [v8eval_root + '/build']
if platform == "linux" or platform == "linux2":
    library_dirs += [v8_dir + '/out/x64.release/obj.target/tools/gyp',
                     v8_dir + '/out/x64.release/obj.target/third_party/icu']
elif platform == "darwin":
    library_dirs += [v8_dir + '/out/x64.release']
library_dirs += [uv_dir + '/.libs']

v8eval_module = Extension(
    '_v8eval',
    sources=[v8eval_root + '/python/v8eval/v8eval_wrap.cxx'],
    libraries=['v8eval',
               'v8_libplatform',
               'v8_base',
               'v8_libbase',
               'v8_nosnapshot',
               'icui18n',
               'icuuc',
               'icudata',
               'uv'],
    include_dirs=include_dirs,
    library_dirs=library_dirs,
    extra_compile_args=['-O3',
                        '-std=c++11'])


# make description
description = 'Run JavaScript engine V8 in Python'
long_description = description
try:
    import pypandoc
    long_description = pypandoc.convert('README.md', 'rst')
except ImportError:
    pass

# setup v8eval package
setup(name='v8eval',
      version='0.1.4',
      author='Yoshiyuki Mineo',
      author_email='Yoshiyuki.Mineo@jp.sony.com',
      license='MIT',
      url='https://github.com/sony/v8eval',
      description=description,
      long_description=long_description,
      keywords='v8 js javascript binding',
      ext_modules=[v8eval_module],
      py_modules=['v8eval'],
      package_dir={'': 'python/v8eval'},
      classifiers=["License :: OSI Approved :: MIT License",
                   "Programming Language :: Python :: 2.7",
                   "Programming Language :: Python :: 3.5",
                   "Programming Language :: Python :: Implementation :: CPython",
                   "Operating System :: POSIX :: Linux",
                   "Operating System :: MacOS :: MacOS X",
                   "Intended Audience :: Developers",
                   "Topic :: Software Development :: Libraries"])
