cmake_minimum_required(VERSION 3.14)

set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")

# Configuration provided via flutter tool.
include(${EPHEMERAL_DIR}/generated_config.cmake OPTIONAL RESULT_VARIABLE _res)

# TODO: Move the rest of this into files in ephemeral. See
# https://github.com/flutter/flutter/issues/57146.

# Serves the same purpose as list(TRANSFORM ... PREPEND ...) which isn't
# available until CMake 3.12.
function(list_prepend LIST_NAME PREFIX)
    set(NEW_LIST "")
    foreach(element ${${LIST_NAME}})
        list(APPEND NEW_LIST "${PREFIX}${element}")
    endforeach(element)
    set(${LIST_NAME} "${NEW_LIST}" PARENT_SCOPE)
endfunction()

# === Flutter Library ===
# System-level dependencies.
find_package(OpenGL REQUIRED)

set(FLUTTER_LIBRARY "${EPHEMERAL_DIR}/flutter_windows.dll")

# Published to parent scope for install step.
set(FLUTTER_LIBRARY ${FLUTTER_LIBRARY} PARENT_SCOPE)
set(FLUTTER_ICU_DATA_FILE "${EPHEMERAL_DIR}/icudtl.dat" PARENT_SCOPE)
set(PROJECT_BUILD_DIR "${PROJECT_DIR}/build/" PARENT_SCOPE)
set(AOT_LIBRARY "${PROJECT_DIR}/build/windows/app.so" PARENT_SCOPE)

list(APPEND FLUTTER_LIBRARY_HEADERS
  "flutter_export.h"
  "flutter_windows.h"
  "flutter_messenger.h"
  "flutter_plugin_registrar.h"
  "flutter_texture_registrar.h"
)
list_prepend(FLUTTER_LIBRARY_HEADERS "${EPHEMERAL_DIR}/")
add_library(flutter INTERFACE)
target_include_directories(flutter INTERFACE
  "${EPHEMERAL_DIR}"
)
target_link_libraries(flutter INTERFACE "${FLUTTER_LIBRARY}.lib")
add_dependencies(flutter flutter_assemble)

# === Flutter tool backend ===
set(FLUTTER_TOOL_ENVIRONMENT
  "FLUTTER_STORAGE_BASE_URL=$ENV{FLUTTER_STORAGE_BASE_URL}"
)
set(FLUTTER_ROOT "$ENV{FLUTTER_ROOT}")

add_custom_command(
  OUTPUT ${FLUTTER_LIBRARY} ${FLUTTER_LIBRARY_HEADERS}
    "${CMAKE_CURRENT_BINARY_DIR}/_phony_"
  COMMAND ${CMAKE_COMMAND} -E env
    ${FLUTTER_TOOL_ENVIRONMENT}
    "${FLUTTER_ROOT}/bin/flutter"
    assemble
    --no-version-check
    --depfile "${CMAKE_CURRENT_BINARY_DIR}/flutter_assemble.d"
    --output "${CMAKE_CURRENT_BINARY_DIR}/ephemeral/"
    -dTargetPlatform=windows-x64
    -dTrackWidgetCreation=true
    -dBuildMode=$<$<CONFIG:Debug>:debug>$<$<CONFIG:Profile>:profile>$<$<CONFIG:Release>:release>
    -dTargetFile="${CMAKE_CURRENT_SOURCE_DIR}/../../lib/main.dart"
    -dProjectDir="${CMAKE_CURRENT_SOURCE_DIR}/../../"
    -dFlutterRoot="${FLUTTER_ROOT}"
    $<$<CONFIG:Debug>:debug>$<$<CONFIG:Profile>:profile>$<$<CONFIG:Release>:release>_bundle_windows_assets
  VERBATIM
)
add_custom_target(flutter_assemble DEPENDS
  "${FLUTTER_LIBRARY}"
  ${FLUTTER_LIBRARY_HEADERS}
)
