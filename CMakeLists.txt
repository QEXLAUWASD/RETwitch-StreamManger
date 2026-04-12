# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (c) 2024-2025 CMake Common Modules
#
# Main CMakeLists.txt - Top-level Build Configuration
#
# This is the entry point for the CMake build system.

include_guard(GLOBAL)

# ============================================================================
# CMake Minimum Version
# ============================================================================

cmake_minimum_required(VERSION 3.26...3.30)

# ============================================================================
# Read buildspec.json for project metadata (before project() call)
# ============================================================================

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/buildspec.json")
    file(READ "${CMAKE_CURRENT_SOURCE_DIR}/buildspec.json" _buildspec_content)
    string(JSON _name ERROR_VARIABLE _err GET "${_buildspec_content}" name)
    string(JSON _version ERROR_VARIABLE _err GET "${_buildspec_content}" version)
    string(JSON _description ERROR_VARIABLE _err GET "${_buildspec_content}" displayName)
endif()

if(NOT _name)
    set(_name "RETwitchTitleUpdater")
endif()
if(NOT _version)
    set(_version "1.0.0")
endif()
if(NOT _description)
    set(_description "RETwitch Title Updater")
endif()

# ============================================================================
# Project Definition - Must be before any other CMake commands
# ============================================================================

project(
    ${_name}
    VERSION ${_version}
    DESCRIPTION "${_description}"
    HOMEPAGE_URL "https://github.com/QEXLAUWASD/Twitch-StreamManger"
    LANGUAGES CXX C
)

# ============================================================================
# Dependency Setup (downloads OBS SDK + Qt to .deps/ if needed)
# ============================================================================

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/common")

if(WIN32)
    include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/windows/buildspec.cmake")
elseif(APPLE)
    include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/macos/buildspec.cmake")
endif()

# ============================================================================
# Build Options
# ============================================================================

option(ENABLE_FRONTEND_API "Use obs-frontend-api for UI functionality" ON)
option(ENABLE_QT "Use Qt functionality" ON)
option(ENABLE_TESTS "Build test suite" ON)
option(ENABLE_SANITIZERS "Enable sanitizers for debugging" OFF)
option(ENABLE_COVERAGE "Enable code coverage" OFF)
option(ENABLE_WARNINGS_AS_ERRORS "Treat warnings as errors" OFF)

# ============================================================================
# Compiler Flags
# ============================================================================

if(STRICT_WARNINGS)
    # GCC/Clang flags
    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        add_compile_options(
            -Wall
            -Wextra
            -Wpedantic
            -Werror=return-type
            -Wno-unused-parameter
            -Wno-unused-function
            -Wno-unused-variable
            -Wno-missing-field-initializers
            -Wno-sign-compare
            -Wno-unused-but-set-variable
            -Wno-unused-value
        )
    endif()
    
    # MSVC flags
    if(MSVC)
        add_compile_options(
            /W4
            /WX-
            /permissive-
            /Zc:__cplusplus
            /Zc:forScope
            /Zc:strictStrings
            /Zc:throwingNew
            /utf-8
        )
    endif()
endif()

# ============================================================================
# Source Files
# ============================================================================

# Main plugin file
set(SOURCES
    src/plugin-main.cpp
    src/AppState.hpp
    src/ConfigStore.hpp
    src/ConfigStore.cpp
    src/ProcessMonitor.hpp
    src/ProcessMonitor.cpp
    src/TwitchClient.hpp
    src/TwitchClient.cpp
    src/TwitchAutoTitleDialog.hpp
    src/TwitchAutoTitleDialog.cpp
)

# ============================================================================
# Create Library Target
# ============================================================================

add_library(${PROJECT_NAME} MODULE ${SOURCES})

# ============================================================================
# Set Target Properties
# ============================================================================

# Target name
set_target_properties(${PROJECT_NAME} PROPERTIES
    OUTPUT_NAME ${PROJECT_NAME}
    PREFIX ""
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON
    POSITION_INDEPENDENT_CODE ON
    AUTOMOC ON
    AUTOUIC ON
    AUTORCC ON
)

# ============================================================================
# Link Libraries
# ============================================================================

# OBS Studio
find_package(libobs REQUIRED HINTS ${OBS_DIR} $ENV{OBS_DIR})
target_link_libraries(${PROJECT_NAME} PRIVATE OBS::libobs)

# OBS Frontend API (if enabled)
if(ENABLE_FRONTEND_API)
    find_package(obs-frontend-api REQUIRED)
    target_link_libraries(${PROJECT_NAME} PRIVATE OBS::obs-frontend-api)
endif()

# Qt Framework (if enabled)
if(ENABLE_QT)
    find_package(Qt6 REQUIRED COMPONENTS Widgets Core Network)
    target_link_libraries(
        ${PROJECT_NAME}
        PRIVATE Qt6::Core Qt6::Widgets Qt6::Network
    )
endif()

# ============================================================================
# Platform-Specific Linking
# ============================================================================

if(WIN32)
    # Link psapi for process enumeration
    target_link_libraries(${PROJECT_NAME} PRIVATE psapi)
    
    # Ship the Qt TLS backend (Schannel) alongside the plugin so HTTPS works.
    find_file(
        QT_SCHANNEL_DLL
        NAMES qschannelbackend.dll
        PATHS "${Qt6_DIR}/../../../plugins/tls"
              "${Qt6Core_DIR}/../../../plugins/tls"
        NO_DEFAULT_PATH
    )
    if(QT_SCHANNEL_DLL)
        add_custom_command(
            TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory
                    "$<TARGET_FILE_DIR:${PROJECT_NAME}>/tls"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${QT_SCHANNEL_DLL}"
                    "$<TARGET_FILE_DIR:${PROJECT_NAME}>/tls/qschannelbackend.dll"
            COMMENT "Copying Qt TLS plugin (qschannelbackend.dll)"
        )
        install(
            FILES "${QT_SCHANNEL_DLL}"
            DESTINATION "obs-plugins/64bit/tls"
            COMPONENT Runtime
        )
    else()
        message(WARNING "qschannelbackend.dll not found — HTTPS may not work")
    endif()
endif()

# ============================================================================
# Installation
# ============================================================================

# Install the plugin (must come before include(install.cmake) to create the export set)
install(TARGETS ${PROJECT_NAME}
    EXPORT "${PROJECT_NAME}Targets"
    LIBRARY DESTINATION "obs-plugins/64bit"
    RUNTIME DESTINATION "obs-plugins/64bit"
    COMPONENT Runtime
)

# Install headers
install(DIRECTORY "src/"
    DESTINATION "include/${PROJECT_NAME}"
    COMPONENT Development
)

include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/install.cmake")

# ============================================================================
# Testing
# ============================================================================

if(ENABLE_TESTS)
    include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/tests.cmake")
endif()

# ============================================================================
# Verification Target
# ============================================================================

if(ENABLE_VERIFICATION)
    include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/verification.cmake")
endif()

# ============================================================================
# Summary
# ============================================================================

include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/summary.cmake")

generate_summary()

# ============================================================================
# Output
# ============================================================================

message(STATUS "")
message(STATUS "============================================================")
message(STATUS "  PROJECT: ${PROJECT_NAME}")
message(STATUS "  VERSION: ${PROJECT_VERSION}")
message(STATUS "  DESCRIPTION: ${PROJECT_DESCRIPTION}")
message(STATUS "  TYPE: MODULE")
message(STATUS "  BUILD_TYPE: ${CMAKE_BUILD_TYPE}")
message(STATUS "  COMPILER: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
message(STATUS "  PLATFORM: ${CMAKE_SYSTEM_NAME}")
message(STATUS "============================================================")

# ============================================================================
# Return success
# ============================================================================

return()