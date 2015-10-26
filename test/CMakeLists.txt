cmake_minimum_required(VERSION 2.8)

project(v8eval-test)

add_executable(v8eval-test
    v8eval_test.cxx
)

set_target_properties(v8eval-test PROPERTIES
    COMPILE_FLAGS "${v8eval-cflags}"
)

set(v8eval-linklibs
    v8eval
    v8_libplatform
    v8_base
    v8_libbase
    v8_nosnapshot
    icui18n
    icuuc
    icudata
    uv
    gtest
    gtest_main
)

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(v8eval-linklibs
        ${v8eval-linklibs}
        dl
        pthread
    )
endif(CMAKE_SYSTEM_NAME STREQUAL "Linux")

target_link_libraries(v8eval-test
    ${v8eval-linklibs}
)

add_subdirectory(googletest/googletest)
