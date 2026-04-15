cmake_minimum_required(VERSION 3.14)
project(swift_share LANGUAGES CXX)

set(BINARY_NAME "swift_share")
cmake_policy(SET CMP0063 NEW)

set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/install")
set(CMAKE_EXPORT_COMPILE_COMMANDS OFF)

if(FLUTTER_TARGET_PLATFORM_SYSROOT)
  set(CMAKE_SYSROOT ${FLUTTER_TARGET_PLATFORM_SYSROOT})
endif()

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
