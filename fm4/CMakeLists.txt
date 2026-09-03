# fm4 - ReXGlue Recompiled Project
#
# SDK boilerplate lives in generated/rexglue.cmake.

cmake_minimum_required(VERSION 3.25)
project(fm4 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(generated/rexglue.cmake)

# Sources
set(FM4_SOURCES
    src/main.cpp
    src/hooks.cpp
    src/fm4_app.cpp
)

if(WIN32)
    add_executable(fm4 WIN32 ${FM4_SOURCES})
else()
    add_executable(fm4 ${FM4_SOURCES})
endif()

rexglue_setup_target(fm4 GPU_PLUGINS xenos)

set(FM4_REGISTER_CPP
    "${CMAKE_CURRENT_SOURCE_DIR}/generated/default/fm4_register.cpp"
)
set(FM4_INIT_CPP
    "${CMAKE_CURRENT_SOURCE_DIR}/generated/default/fm4_init.cpp"
)
set(FM4_REGISTER_SPLIT_STAMP
    "${CMAKE_CURRENT_BINARY_DIR}/fm4_register.split.stamp"
)

# FM4 code generation emits an unusually large registrar. Split it
# automatically before every compile where the generated source is newer than
# the stamp.
add_custom_command(
    OUTPUT "${FM4_REGISTER_SPLIT_STAMP}"
    COMMAND powershell.exe -NoProfile -ExecutionPolicy Bypass
            -File "${CMAKE_CURRENT_SOURCE_DIR}/../Split FM4 Registrar.ps1"
            -Path "${FM4_REGISTER_CPP}"
    COMMAND "${CMAKE_COMMAND}" -E touch "${FM4_REGISTER_SPLIT_STAMP}"
    DEPENDS
        "${FM4_REGISTER_CPP}"
        "${CMAKE_CURRENT_SOURCE_DIR}/../Split FM4 Registrar.ps1"
    VERBATIM
)
add_custom_target(fm4_split_register DEPENDS "${FM4_REGISTER_SPLIT_STAMP}")
add_dependencies(fm4 fm4_split_register)

# The split turns the generated 292k-call registrar into bounded noinline
# helpers, allowing clang to compile at O0 without one invalid giant function.
set_source_files_properties(
    "${FM4_REGISTER_CPP}"
    PROPERTIES
        COMPILE_OPTIONS "-O0"
        SKIP_PRECOMPILE_HEADERS ON
)

# The generated dispatcher is also large enough for release optimization to
# exhaust memory on a busy development machine. It is startup-only glue, so
# compiling it at O0 has no effect on recompiled game-code performance.
set_source_files_properties(
    "${FM4_INIT_CPP}"
    PROPERTIES
        COMPILE_OPTIONS "-O0"
        SKIP_PRECOMPILE_HEADERS ON
)
