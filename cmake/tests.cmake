# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (c) 2024-2025 CMake Common Modules
#
# Comprehensive Test Suite Configuration
#
# This module configures CTest with advanced features for testing.

include_guard(GLOBAL)

# ============================================================================
# Test Options
# ============================================================================

# Enable test suite
set(ENABLE_TESTS ON CACHE BOOL "Enable test suite" FORCE)

# Test timeout in seconds
set(TEST_TIMEOUT 300 CACHE STRING "Test timeout in seconds")

# Enable parallel test execution
set(TEST_PARALLEL ON CACHE BOOL "Enable parallel test execution" FORCE)

# Test categories
set(TEST_CATEGORIES
    "unit"       "Unit tests"
    "integration" "Integration tests"
    "system"      "System tests"
    "performance" "Performance tests"
    "stress"      "Stress tests"
    CACHE STRING "Test categories")

# ============================================================================
# Test Configuration Functions
# ============================================================================

function(configure_test_suite)
    message(STATUS "Configuring test suite...")
    
    # -----------------------------------------------------------------------------
    # CTest Settings
    # -----------------------------------------------------------------------------
    # Set test timeout
    set(CTEST_TEST_TIMEOUT ${TEST_TIMEOUT})
    
    # Enable parallel execution
    if(TEST_PARALLEL)
        set(CMAKE_TEST_PARALLEL ON)
        set(CTest_TEST_PARALLEL 1)
    endif()
    
    # Set test directory
    set(CTEST_TEST_DIRECTORY "${CMAKE_BINARY_DIR}/test_results")
    
    # -----------------------------------------------------------------------------
    # Test Output Configuration
    # -----------------------------------------------------------------------------
    # Set output format
    set(CTEST_OUTPUT_ON_FAILURE "always")
    set(CTEST_OUTPUT_ON_SUCCESS "never")
    
    # Set output file
    set(CTEST_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/test_output")
    
    # -----------------------------------------------------------------------------
    # Test Discovery
    # -----------------------------------------------------------------------------
    # Enable test discovery
    set(ENABLE_TEST_DISCOVERY ON)
    
    # Test discovery timeout
    set(DISCOVERY_TIMEOUT 60)
    
    # -----------------------------------------------------------------------------
    # Test Labels and Categories
    # -----------------------------------------------------------------------------
    # Define test labels for filtering
    set(TEST_LABELS
        "unit"
        "integration"
        "system"
        "performance"
        "stress"
        "sanitizer"
        "ci"
        "local"
    )
    
    # -----------------------------------------------------------------------------
    # Test Environment
    # -----------------------------------------------------------------------------
    # Set test environment variables
    set(CTest_TEST_ENVIRONMENT
        "CTEST_OUTPUT_ON_FAILURE=always"
        "CTEST_OUTPUT_ON_SUCCESS=never"
        "CTEST_PARALLEL_LEVEL=4"
    )
    
    # -----------------------------------------------------------------------------
    # Test Discovery Commands
    # -----------------------------------------------------------------------------
    set(DISCOVERY_COMMANDS
        "find_tests"
        "discover_tests"
    )
    
    # -----------------------------------------------------------------------------
    # Test Report Configuration
    # -----------------------------------------------------------------------------
    set(CTEST_REPORT_FORMAT "xml")
    set(CTEST_REPORT_LOCATION "${CMAKE_BINARY_DIR}/test_report.xml")
    
    # -----------------------------------------------------------------------------
    # Test Dependencies
    # -----------------------------------------------------------------------------
    # Link GoogleTest or Catch2 if available
    find_package(GTest QUIET)
    if(GTest_FOUND)
        message(STATUS "GoogleTest found: ${GTest_VERSION}")
        include(GoogleTest)
    elseif(Catch2_FOUND)
        message(STATUS "Catch2 found: ${Catch2_VERSION}")
    else()
        message(WARNING "No test framework found. Tests may not be available.")
    endif()
    
    message(STATUS "Test suite configuration completed.")
endfunction()

# ============================================================================
# Test Helper Functions
# ============================================================================

function(add_test_with_options name source_files categories)
    add_executable(${name} ${source_files})
    
    # Set test properties
    set_tests_properties(${name} PROPERTIES
        LABELS "${categories}"
        TIMEOUT "${TEST_TIMEOUT}"
        FIXTURES_REQUIRED ""
    )
    
    # Add to test suite
    add_test(NAME ${name}
        COMMAND ${name}
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/test_results")
endfunction()

# ============================================================================
# Main Execution
# ============================================================================

configure_test_suite()