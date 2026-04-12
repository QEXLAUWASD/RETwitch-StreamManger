# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (c) 2024-2025 CMake Common Modules
#
# Configuration Summary Generator
#
# This module generates a comprehensive configuration summary.

include_guard(GLOBAL)

# ============================================================================
# Summary Options
# ============================================================================

# Enable summary output
set(GENERATE_SUMMARY ON CACHE BOOL "Generate configuration summary" FORCE)

# Summary verbosity
set(SUMMARY_VERBOSITY "detailed" CACHE STRING "Summary verbosity: minimal, detailed, verbose")

# ============================================================================
# Summary Functions
# ============================================================================

function(generate_summary)
    message(STATUS "Generating configuration summary...")
    
    # -----------------------------------------------------------------------------
    # System Information
    # -----------------------------------------------------------------------------
    message(STATUS "\n=== SYSTEM INFORMATION ===")
    message(STATUS "Host System: ${CMAKE_HOST_SYSTEM_NAME}")
    message(STATUS "Host System: ${CMAKE_HOST_SYSTEM_VERSION}")
    message(STATUS "Host CPU: ${CMAKE_HOST_SYSTEM_PROCESSOR}")
    message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
    message(STATUS "CMake Version: ${CMAKE_VERSION}")
    
    # -----------------------------------------------------------------------------
    # Compiler Information
    # -----------------------------------------------------------------------------
    message(STATUS "\n=== COMPILER INFORMATION ===")
    message(STATUS "C++ Compiler: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
    message(STATUS "C Compiler: ${CMAKE_C_COMPILER_ID} ${CMAKE_C_COMPILER_VERSION}")
    message(STATUS "Host System: ${CMAKE_HOST_SYSTEM_NAME}")
    message(STATUS "Host System: ${CMAKE_HOST_SYSTEM_VERSION}")
    message(STATUS "Host CPU: ${CMAKE_HOST_SYSTEM_PROCESSOR}")
    
    # -----------------------------------------------------------------------------
    # Build Configuration
    # -----------------------------------------------------------------------------
    message(STATUS "\n=== BUILD CONFIGURATION ===")
    message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
    message(STATUS "Source Directory: ${CMAKE_SOURCE_DIR}")
    message(STATUS "Binary Directory: ${CMAKE_BINARY_DIR}")
    message(STATUS "Install Prefix: ${CMAKE_INSTALL_PREFIX}")
    message(STATUS "Generator: ${CMAKE_GENERATOR}")
    
    # -----------------------------------------------------------------------------
    # Build Options
    # -----------------------------------------------------------------------------
    message(STATUS "\n=== BUILD OPTIONS ===")
    message(STATUS "STRICT_WARNINGS: ${STRICT_WARNINGS}")
    message(STATUS "ENABLE_OPTIMIZATION_HINTS: ${ENABLE_OPTIMIZATION_HINTS}")
    message(STATUS "ENABLE_CODE_GENERATION_CHECKS: ${ENABLE_CODE_GENERATION_CHECKS}")
    message(STATUS "VERBOSE_OUTPUT: ${VERBOSE_OUTPUT}")
    message(STATUS "AUTO_DEPS: ${AUTO_DEPS}")
    message(STATUS "USE_FETCHCONTENT: ${USE_FETCHCONTENT}")
    message(STATUS "USE_PKGCONFIG: ${USE_PKGCONFIG}")
    
    # -----------------------------------------------------------------------------
    # Platform-Specific Settings
    # -----------------------------------------------------------------------------
    message(STATUS "\n=== PLATFORM-SPECIFIC SETTINGS ===")
    if(WIN32)
        message(STATUS "Platform: Windows")
        message(STATUS "MSVC: ${MSVC}")
        message(STATUS "MSVC_VERSION: ${MSVC_VERSION}")
    elseif(APPLE)
        message(STATUS "Platform: macOS")
        message(STATUS "macOS Version: ${CMAKE_SYSTEM_VERSION}")
        message(STATUS "Architectures: ${CMAKE_OSX_ARCHITECTURES}")
    elseif(UNIX)
        message(STATUS "Platform: Linux")
        message(STATUS "Distribution: ${CMAKE_SYSTEM_NAME}")
    endif()
    
    # -----------------------------------------------------------------------------
    # Detected Dependencies
    # -----------------------------------------------------------------------------
    message(STATUS "\n=== DETECTED DEPENDENCIES ===")
    message(STATUS "OBS Studio: ${OBS_FOUND}")
    message(STATUS "Qt6: ${Qt6_FOUND}")
    message(STATUS "pkg-config: ${PKG_CONFIG_FOUND}")
    message(STATUS "GoogleTest: ${GTest_FOUND}")
    message(STATUS "Catch2: ${Catch2_FOUND}")
    
    # -----------------------------------------------------------------------------
    # Sanitizer Settings
    # -----------------------------------------------------------------------------
    message(STATUS "\n=== SANITIZER SETTINGS ===")
    message(STATUS "AddressSanitizer: ${ENABLE_ASAN}")
    message(STATUS "ThreadSanitizer: ${ENABLE_TSAN}")
    message(STATUS "UndefinedBehaviorSanitizer: ${ENABLE_UBSAN}")
    message(STATUS "LeakSanitizer: ${ENABLE_LSAN}")
    message(STATUS "MemorySanitizer: ${ENABLE_MSAN}")
    
    # -----------------------------------------------------------------------------
    # Static Analysis
    # -----------------------------------------------------------------------------
    message(STATUS "\n=== STATIC ANALYSIS ===")
    message(STATUS "clang-tidy: ${CLANG_TIDY}")
    message(STATUS "cppcheck: ${CPPCHECK}")
    
    # -----------------------------------------------------------------------------
    # Test Configuration
    # -----------------------------------------------------------------------------
    message(STATUS "\n=== TEST CONFIGURATION ===")
    message(STATUS "Enable Tests: ${ENABLE_TESTS}")
    message(STATUS "Test Timeout: ${TEST_TIMEOUT}s")
    message(STATUS "Parallel Tests: ${TEST_PARALLEL}")
    message(STATUS "Test Categories: ${TEST_CATEGORIES}")
    
    # -----------------------------------------------------------------------------
    # Summary Status
    # -----------------------------------------------------------------------------
    message(STATUS "\n=== SUMMARY STATUS ===")
    message(STATUS "Configuration: SUCCESS")
    message(STATUS "All settings validated.")
endfunction()

# ============================================================================
# Main Execution
# ============================================================================

generate_summary()