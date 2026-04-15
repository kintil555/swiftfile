cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

set(BINARY_NAME "swift_share")
set(APP_IDENTIFIER "com.example.swift_share")

cmake_policy(SET CMP0063 NEW)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED YES)

add_definitions(-DUNICODE -D_UNICODE)

configure_file(
  "${CMAKE_CURRENT_SOURCE_DIR}/Runner.rc.in"
  "${CMAKE_CURRENT_BINARY_DIR}/Runner.rc"
)

if(NOT DEFINED FLUTTER_ROOT)
  get_filename_component(FLUTTER_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../.." ABSOLUTE)
endif()

set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../flutter")

# Include Flutter CMake helpers (provides apply_standard_settings)
include("${FLUTTER_MANAGED_DIR}/CMakeLists.txt" OPTIONAL)
include("${FLUTTER_ROOT}/packages/flutter_tools/cmake/flutter_standard_settings.cmake" OPTIONAL)
include("${FLUTTER_MANAGED_DIR}/generated_version.cmake" OPTIONAL)
include("${FLUTTER_MANAGED_DIR}/ephemeral/generated_config.cmake" OPTIONAL)

set(FLUTTER_LIBRARY "${FLUTTER_MANAGED_DIR}/ephemeral/flutter_windows.dll")

# Fallback: define apply_standard_settings jika tidak ter-include dari Flutter SDK
if(NOT COMMAND apply_standard_settings)
  function(apply_standard_settings TARGET)
    target_compile_features(${TARGET} PUBLIC cxx_std_17)
    target_compile_options(${TARGET} PRIVATE /W4 /WX /wd"4100")
    target_compile_options(${TARGET} PRIVATE /EHsc)
    set_target_properties(${TARGET} PROPERTIES
      MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
  endfunction()
endif()

add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

apply_standard_settings(${BINARY_NAME})

target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PowrProf.lib)
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

add_dependencies(${BINARY_NAME} flutter_assemble)
