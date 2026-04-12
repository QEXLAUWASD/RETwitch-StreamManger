# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (c) 2024-2025 CMake Common Modules
#
# Dependency Resolution and Management
#
# This module handles automatic dependency resolution with fallback mechanisms.

include_guard(GLOBAL)

# ============================================================================
# Dependency Options
# ============================================================================

# Enable automatic dependency resolution
set(AUTO_DEPS ON CACHE BOOL "Enable automatic dependency resolution" FORCE)

# Enable FetchContent fallback
set(USE_FETCHCONTENT ON CACHE BOOL "Use FetchContent for missing dependencies" FORCE)

# Enable pkg-config as secondary search
set(USE_PKGCONFIG ON CACHE BOOL "Use pkg-config as secondary search" FORCE)

# Minimum dependency versions
set(MIN_OBS_VERSION "0.27.0" CACHE STRING "Minimum OBS Studio version")
set(MIN_QT_VERSION "6.5.0" CACHE STRING "Minimum Qt version")

# ============================================================================
# Dependency Resolution Function
# ============================================================================

function(resolve_dependencies)
    message(STATUS "Resolving dependencies...")
    
    # -----------------------------------------------------------------------------
    # OBS Studio
    # -----------------------------------------------------------------------------
    message(STATUS "Checking OBS Studio dependency...")
    
    find_package(OBS REQUIRED)
    
    if(NOT OBS_FOUND)
        if(USE_FETCHCONTENT)
            resolve_with_fetchcontent(OBS)
        else()
            message(FATAL_ERROR "OBS Studio not found and FetchContent disabled.")
        endif()
    else()
        message(STATUS "OBS Studio ${OBS_VERSION} found")
    endif()
    
    # -----------------------------------------------------------------------------
    # Qt Framework
    # -----------------------------------------------------------------------------
    message(STATUS "Checking Qt framework...")
    
    find_package(Qt6 ${MIN_QT_VERSION} COMPONENTS Core Widgets Network REQUIRED)
    
    if(NOT Qt6_FOUND)
        if(USE_FETCHCONTENT)
            resolve_with_fetchcontent(Qt6)
        else()
            message(FATAL_ERROR "Qt6 not found and FetchContent disabled.")
        endif()
    else()
        message(STATUS "Qt6 ${Qt6_VERSION} found")
    endif()
    
    # -----------------------------------------------------------------------------
    # pkg-config (Secondary Search)
    # -----------------------------------------------------------------------------
    if(USE_PKGCONFIG)
        find_package(PkgConfig QUIET)
        
        if(PKG_CONFIG_FOUND)
            message(STATUS "pkg-config found: ${PKG_CONFIG_EXECUTABLE}")
            
            # Check for optional dependencies via pkg-config
            pkg_check_modules(OPTIONAL_LIBS QUIET 
                "libobs" "obs-frontend-api" "zlib")
            
            if(OPTIONAL_LIBS_FOUND)
                message(STATUS "Optional dependencies found via pkg-config")
            endif()
        else()
            message(WARNING "pkg-config not found. Some optional checks may be disabled.")
        endif()
    endif()
    
    message(STATUS "Dependency resolution completed.")
endfunction()

# ============================================================================
# FetchContent Fallback
# ============================================================================

function(resolve_with_fetchcontent package)
    message(STATUS "Falling back to FetchContent for ${package}...")
    
    include(FetchContent)
    
    # Set up FetchContent properties
    set(FETCHCONTENT_QUIET OFF)
    set(FETCHCONTENT_UPDATES_DISCONNECTED ON)
    
    # Package-specific handling
    if(package STREQUAL "OBS")
        # OBS Studio is complex - requires manual handling
        message(FATAL_ERROR "OBS Studio cannot be fetched automatically. Please install OBS Studio SDK.")
    elseif(package STREQUAL "Qt6")
        # Qt is typically installed system-wide
        message(FATAL_ERROR "Qt6 should be installed system-wide. Please install Qt 6.5+.")
    else()
        # Generic FetchContent handling
        FetchContent_Declare(
            ${package}
            URL "https://github.com/yourorg/${package}.git"
            GIT_TAG "v${MIN_QT_VERSION}")
        
        FetchContent_MakeAvailable(${package})
    endif()
endfunction()

# ============================================================================
# Static Analysis Dependencies
# ============================================================================

function(resolve_static_analysis_deps)
    message(STATUS "Checking static analysis tools...")
    
    # Clang-Tidy
    find_program(CLANG_TIDY "clang-tidy")
    if(CLANG_TIDY)
        message(STATUS "clang-tidy found: ${CLANG_TIDY}")
        set(CLANG_TIDY_AVAILABLE TRUE)
    else()
        message(WARNING "clang-tidy not found")
        set(CLANG_TIDY_AVAILABLE FALSE)
    endif()
    
    # Cppcheck
    find_program(CPPCHECK "cppcheck")
    if(CPPCHECK)
        message(STATUS "cppcheck found: ${CPPCHECK}")
        set(CPPCHECK_AVAILABLE TRUE)
    else()
        message(WARNING "cppcheck not found")
        set(CPPCHECK_AVAILABLE FALSE)
    endif()
    
    # Coverity
    find_program(COVERITY_ANALYZER "cov-analysis")
    if(COVERITY_ANALYZER)
        message(STATUS "Coverity analyzer found")
        set(COVERITY_AVAILABLE TRUE)
    else()
        message(WARNING "Coverity analyzer not found")
        set(COVERITY_AVAILABLE FALSE)
    endif()
    
    message(STATUS "Static analysis dependencies checked.")
endfunction()

# ============================================================================
# Main Execution
# ============================================================================

resolve_dependencies()
resolve_static_analysis_deps()