# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (c) 2024-2025 CMake Common Modules
#
# CMake Bootstrap Module - OBS Plugin Edition
#
# This module initializes the build environment for OBS plugins.
# It extends the existing bootstrap functionality with comprehensive
# modern CMake features while maintaining OBS plugin compatibility.

include_guard(GLOBAL)

# ============================================================================
# CMake Version Check
# ============================================================================

# Require minimum CMake version for modern features
if(CMAKE_VERSION VERSION_LESS 3.26)
    message(FATAL_ERROR 
        "CMake ${CMAKE_VERSION} is too old. "
        "This project requires CMake 3.26 or later.")
endif()

message(STATUS "CMake ${CMAKE_VERSION} detected")

# ============================================================================
# Existing OBS Plugin Bootstrap (Preserved)
# ============================================================================

# Map fallback configurations for optimized build configurations
# gersemi: off
set(
  CMAKE_MAP_IMPORTED_CONFIG_RELWITHDEBINFO
    RelWithDebInfo
    Release
    MinSizeRel
    None
    ""
)
set(
  CMAKE_MAP_IMPORTED_CONFIG_MINSIZEREL
    MinSizeRel
    Release
    RelWithDebInfo
    None
    ""
)
set(
  CMAKE_MAP_IMPORTED_CONFIG_RELEASE
    Release
    RelWithDebInfo
    MinSizeRel
    None
    ""
)
# gersemi: on

# Prohibit in-source builds
if("${CMAKE_CURRENT_BINARY_DIR}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}")
    message(
        FATAL_ERROR
        "In-source builds are not supported. "
        "Specify a build directory via 'cmake -S <SOURCE DIRECTORY> -B <BUILD_DIRECTORY>' instead."
    )
    file(REMOVE_RECURSE "${CMAKE_CURRENT_SOURCE_DIR}/CMakeCache.txt" "${CMAKE_CURRENT_SOURCE_DIR}/CMakeFiles")
endif()

# Add common module directories to default search path
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/common")

# ============================================================================
# Modern CMake Extensions
# ============================================================================

# Include modern CMake modules
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/common/policies.cmake")
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/common/defaults.cmake")
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/common/variables.cmake")
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/compilerconfig.cmake")

# ============================================================================
# OBS Plugin Configuration
# ============================================================================

# Allow selection of common build types via UI
if(NOT CMAKE_GENERATOR MATCHES "(Xcode|Visual Studio .+)")
    if(NOT CMAKE_BUILD_TYPE)
        set(
            CMAKE_BUILD_TYPE
            "RelWithDebInfo"
            CACHE STRING
            "OBS build type [Release, RelWithDebInfo, Debug, MinSizeRel]"
            FORCE
        )
        set_property(
            CACHE CMAKE_BUILD_TYPE
            PROPERTY STRINGS Release RelWithDebInfo Debug MinSizeRel
        )
    endif()
endif()

# Disable exports automatically going into the CMake package registry
set(CMAKE_EXPORT_PACKAGE_REGISTRY FALSE)
# Enable default inclusion of targets' source and binary directory
set(CMAKE_INCLUDE_CURRENT_DIR TRUE)

# ============================================================================
# Platform-Specific Settings
# ============================================================================

if(WIN32)
    # Windows-specific settings
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
endif()

if(APPLE)
    # macOS-specific settings
    set(CMAKE_MACOSX_RPATH ON)
endif()

if(UNIX)
    # Linux-specific settings
    set(CMAKE_BUILD_WITH_INSTALL_RPATH ON)
    set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
endif()

# ============================================================================
# Export Compile Commands
# ============================================================================

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ============================================================================
# Final Summary
# ============================================================================

message(STATUS "\n============================================================")
message(STATUS "  CMake Bootstrap Complete")
message(STATUS "  Project: ${PROJECT_NAME}")
message(STATUS "  Version: ${PROJECT_VERSION}")
message(STATUS "  Build:   ${CMAKE_BUILD_TYPE}")
message(STATUS "  Platform: ${CMAKE_SYSTEM_NAME}")
message(STATUS "  Compiler: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
message(STATUS "============================================================")

# ============================================================================
# End of Bootstrap
# ============================================================================

# End of bootstrap module