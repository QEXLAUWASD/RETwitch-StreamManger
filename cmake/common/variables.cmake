# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (c) 2024-2025 CMake Common Modules
#
# Global Variable Exports
#
# This module exports variables for use across all CMake modules.

include_guard(GLOBAL)

# ============================================================================
# Export Common Variables
# ============================================================================

# Project name (exported for use)
set(__CMAKE_PROJECT_NAME "${PROJECT_NAME}" CACHE STRING "Project name" FORCE)

# Project version (exported for use)
set(__CMAKE_PROJECT_VERSION "${PROJECT_VERSION}" CACHE STRING "Project version" FORCE)

# Build type (exported for use)
set(__CMAKE_BUILD_TYPE "${CMAKE_BUILD_TYPE}" CACHE STRING "Build type" FORCE)

# Compiler information (exported for use)
set(__CMAKE_CXX_COMPILER_ID "${CMAKE_CXX_COMPILER_ID}" CACHE STRING "C++ Compiler ID" FORCE)
set(__CMAKE_CXX_COMPILER_VERSION "${CMAKE_CXX_COMPILER_VERSION}" CACHE STRING "C++ Compiler Version" FORCE)

# Platform information (exported for use)
set(__CMAKE_SYSTEM_NAME "${CMAKE_SYSTEM_NAME}" CACHE STRING "System Name" FORCE)

# Build configuration (exported for use)
set(__CMAKE_GENERATOR "${CMAKE_GENERATOR}" CACHE STRING "CMake Generator" FORCE)

# ============================================================================
# Export Configuration
# ============================================================================

# Export compile commands (already set in bootstrap.cmake)
# set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ============================================================================
# Helper Functions for Variable Export
# ============================================================================

function(get_project_info)
    set(PROJECT_NAME "${__CMAKE_PROJECT_NAME}" PARENT_SCOPE)
    set(PROJECT_VERSION "${__CMAKE_PROJECT_VERSION}" PARENT_SCOPE)
    set(BUILD_TYPE "${__CMAKE_BUILD_TYPE}" PARENT_SCOPE)
    set(COMPILER_ID "${__CMAKE_CXX_COMPILER_ID}" PARENT_SCOPE)
    set(COMPILER_VERSION "${__CMAKE_CXX_COMPILER_VERSION}" PARENT_SCOPE)
    set(SYSTEM_NAME "${__CMAKE_SYSTEM_NAME}" PARENT_SCOPE)
    set(GENERATOR "${__CMAKE_GENERATOR}" PARENT_SCOPE)
endfunction()

# ============================================================================
# Main Execution
# ============================================================================

get_project_info()