# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (c) 2024-2025 CMake Common Modules
#
# Default Variables for CMake Build System
#
# This module defines default values for project-wide variables.

include_guard(GLOBAL)

# ============================================================================
# Project Identification
# ============================================================================

# Project name - will be overridden by project() call
if(NOT DEFINED _name)
    set(_name "${CMAKE_PROJECT_NAME}" CACHE STRING "Project name")
endif()

# Project version
if(NOT DEFINED _version)
    set(_version "1.0.0" CACHE STRING "Project version")
endif()

# Project description
if(NOT DEFINED _description)
    set(_description "A modern CMake project with comprehensive build system" CACHE STRING "Project description")
endif()

# ============================================================================
# Build Options
# ============================================================================

# Enable strict warnings
if(NOT DEFINED STRICT_WARNINGS)
    set(STRICT_WARNINGS ON CACHE BOOL "Enable strict warning levels" FORCE)
endif()

# Enable compiler optimization hints
if(NOT DEFINED ENABLE_OPTIMIZATION_HINTS)
    set(ENABLE_OPTIMIZATION_HINTS ON CACHE BOOL "Enable compiler optimization hints" FORCE)
endif()

# Enable code generation checks
if(NOT DEFINED ENABLE_CODE_GENERATION_CHECKS)
    set(ENABLE_CODE_GENERATION_CHECKS ON CACHE BOOL "Enable code generation checks" FORCE)
endif()

# Enable verbose output
if(NOT DEFINED VERBOSE_OUTPUT)
    set(VERBOSE_OUTPUT OFF CACHE BOOL "Enable verbose output during build" FORCE)
endif()

# ============================================================================
# Output Directory Configuration
# ============================================================================

# Set default source directory
set(SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}" CACHE PATH "Source directory")

# Set default binary directory (will be overridden by CMAKE_BINARY_DIR)
if(NOT CMAKE_BINARY_DIR)
    set(CMAKE_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Binary output directory" FORCE)
endif()

# ============================================================================
# Build Type Defaults
# ============================================================================

# Default build type - Release if not specified
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Choose the type of build" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS 
        "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

# ============================================================================
# Compiler Warning Flags
# ============================================================================

# Global warning flags
set(CMAKE_CXX_WARNING_FLAGS_GLOBAL 
    "-Wall" 
    "-Wextra" 
    "-Wpedantic"
    CACHE STRING "Global C++ warning flags" FORCE)

# ============================================================================
# Code Coverage Settings
# ============================================================================

# Enable code coverage if requested
if(ENABLE_CODE_COVERAGE)
    set(ENABLE_GCOV ON)
    set(ENABLE_LCOV ON)
endif()

# ============================================================================
# Installation Defaults
# ============================================================================

# Installation prefix
if(NOT CMAKE_INSTALL_PREFIX)
    set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/install" CACHE PATH "Installation prefix" FORCE)
endif()

# Installation configuration
set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib" CACHE PATH "Installation RPATH" FORCE)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH ON)

# ============================================================================
# Module Paths
# ============================================================================

# Add common module path
set(CMAKE_MODULE_PATH
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/common"
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake"
    "${CMAKE_MODULE_PATH}" CACHE PATH "CMake module search path")

# ============================================================================
# Export Configuration
# ============================================================================

# Export compile commands for IDE integration
set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "Export compile commands" FORCE)

# ============================================================================
# Policy Validation
# ============================================================================

# Enable policy validation
set(ENABLE_POLICY_VALIDATION ON CACHE BOOL "Enable CMake policy validation" FORCE)

# ============================================================================
# Final Validation
# ============================================================================

function(validate_defaults)
    message(STATUS "Validating default configuration...")
    
    # Validate project name
    if(_name STREQUAL "")
        message(FATAL_ERROR "Project name is not set. Please specify _name or PROJECT_NAME.")
    endif()
    
    # Validate version format
    string(REGEX MATCH "^[0-9]+\.[0-9]+\.[0-9]+" _version_match "${_version}")
    if(NOT _version_match)
        message(WARNING "Version format may not be semver: ${_version}")
    endif()
    
    # Validate build type
    if(CMAKE_BUILD_TYPE)
        set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
            "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
    endif()
    
    message(STATUS "Default configuration validated successfully.")
endfunction()

validate_defaults()