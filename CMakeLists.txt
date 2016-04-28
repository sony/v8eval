cmake_minimum_required(VERSION 2.8)

project(v8eval)

option(V8EVAL_TEST "Build tests" OFF)

if(COMMAND cmake_policy)
    cmake_policy(SET CMP0015 NEW)
endif(COMMAND cmake_policy)

include_directories(
    v8
    v8/include
    v8/third_party/icu/source/i18n
    v8/third_party/icu/source/common
    uv/include
    src
    test/googletest/googletest/include
)

if(APPLE)
    link_directories(
        v8/out/x64.release
    )
endif(APPLE)

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    link_directories(
        v8/out/x64.release/obj.target/src
        v8/out/x64.release/obj.target/third_party/icu
    )
endif(CMAKE_SYSTEM_NAME STREQUAL "Linux")

link_directories(
    uv/.libs/
)

add_library(v8eval STATIC
    src/v8eval.cxx
    src/dbgsrv.cxx
)

add_library(v8eval_go STATIC
    src/v8eval_go.cxx
)

add_library(v8eval_python STATIC
    src/v8eval_python.cxx
)

add_library(v8eval_ruby STATIC
    src/v8eval_ruby.cxx
)

set(v8eval-cflags
    -Wall
    -Wendif-labels
    -Werror
    -Wno-missing-field-initializers
    -Wno-unused-parameter
    -Wshorten-64-to-32
    -fPIC
    -fno-exceptions
    -fno-rtti
    -fno-strict-aliasing
    -fno-threadsafe-statics
    -fstrict-aliasing
    -fvisibility=hidden
    -fvisibility-inlines-hidden
    -gdwarf-2
    -std=c++11
)

string(REPLACE ";" " " v8eval-cflags "${v8eval-cflags}")

set_target_properties(v8eval PROPERTIES
    COMPILE_FLAGS "${v8eval-cflags}"
)

set_target_properties(v8eval_go PROPERTIES
    COMPILE_FLAGS "${v8eval-cflags}"
)

set_target_properties(v8eval_python PROPERTIES
    COMPILE_FLAGS "${v8eval-cflags}"
)

set_target_properties(v8eval_ruby PROPERTIES
    COMPILE_FLAGS "${v8eval-cflags}"
)

if(V8EVAL_TEST)
    add_subdirectory(test)
endif(V8EVAL_TEST)
