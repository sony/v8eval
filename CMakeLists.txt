cmake_minimum_required(VERSION 2.8)

project(v8eval)

option(V8EVAL_TEST "Build tests" OFF)

if(COMMAND cmake_policy)
    cmake_policy(SET CMP0015 NEW)
endif(COMMAND cmake_policy)

include_directories(
    v8
    v8/include
    src
    v8/third_party/googletest/src/googletest/include
)

set(v8eval-linkdirs
    v8/out.gn/x64.release/obj
    v8/out.gn/x64.release/obj/third_party/googletest
)

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(v8eval-linkdirs
        ${v8eval-linkdirs}
        v8/out.gn/x64.release/obj/buildtools/third_party/libc++
        v8/out.gn/x64.release/obj/buildtools/third_party/libc++abi
    )
endif(CMAKE_SYSTEM_NAME STREQUAL "Linux")

link_directories(
    ${v8eval-linkdirs}
)

add_library(v8eval STATIC
    src/v8eval.cxx
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
    -Werror
    -Wno-missing-field-initializers
    -Wno-unused-parameter
    -Wshorten-64-to-32
    -fPIC
    -fno-exceptions
    -fno-rtti
    -fno-strict-aliasing
    -fno-threadsafe-statics
    -fvisibility=hidden
    -fvisibility-inlines-hidden
    -gdwarf-2
    -std=c++14
)

if(APPLE)
    set(v8eval-cflags
        ${v8eval-cflags}
        -stdlib=libc++
    )
endif(APPLE)

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(v8eval-cflags
        ${v8eval-cflags}
        -nostdinc++
        -isystem ${CMAKE_CURRENT_SOURCE_DIR}/v8/buildtools/third_party/libc++/trunk/include
        -isystem ${CMAKE_CURRENT_SOURCE_DIR}/v8/buildtools/third_party/libc++abi/trunk/include
    )
endif(CMAKE_SYSTEM_NAME STREQUAL "Linux")

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
