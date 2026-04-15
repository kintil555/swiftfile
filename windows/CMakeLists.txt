cmake_minimum_required(VERSION 3.14)
project(swift_share LANGUAGES CXX)

set(BINARY_NAME "swift_share")
cmake_policy(SET CMP0063 NEW)

set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/install")
set(CMAKE_EXPORT_COMPILE_COMMANDS OFF)

if(FLUTTER_TARGET_PLATFORM_SYSROOT)
  set(CMAKE_SYSROOT ${FLUTTER_TARGET_PLATFORM_SYSROOT})
endif()

# Define apply_standard_settings (normally injected by Flutter SDK)
function(apply_standard_settings TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  target_compile_options(${TARGET} PRIVATE /W4 /WX /wd4100 /wd4267)
  target_compile_options(${TARGET} PRIVATE /EHsc)
  set_target_properties(${TARGET} PROPERTIES
    MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endfunction()

# Build runner binary
add_subdirectory("runner")

# Generated plugins build rules
include(flutter/generated_plugins.cmake OPTIONAL)

# === Installation ===
set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")

install(CODE "
  file(REMOVE_RECURSE \"${CMAKE_INSTALL_PREFIX}/\")
  " COMPONENT Runtime)

install(DIRECTORY "${BUILD_BUNDLE_DIR}/"
  DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)
