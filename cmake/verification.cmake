# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (c) 2024-2025 CMake Common Modules
#
# Build Verification Target
#
# This module creates a comprehensive build verification target.

include_guard(GLOBAL)

# ============================================================================
# Verification Options
# ============================================================================

# Enable verification checks
set(ENABLE_VERIFICATION ON CACHE BOOL "Enable verification checks" FORCE)

# Verification timeout
set(VERIFICATION_TIMEOUT 300 CACHE STRING "Verification timeout in seconds")

# ============================================================================
# Verification Functions
# ============================================================================

function(configure_verification)
    message(STATUS "Configuring verification target...")
    
    # Create verification target
    add_custom_target(check
        COMMAND \
            ${CMAKE_COMMAND} --build "${CMAKE_BINARY_DIR}" --target all && \
            ${CMAKE_CTEST_COMMAND} --output-on-failure && \
            ${CMAKE_COMMAND} --build "${CMAKE_BINARY_DIR}" --target install DESTINATION "${CMAKE_BINARY_DIR}/check_install" && \
            ${CMAKE_COMMAND} --build "${CMAKE_BINARY_DIR}" --target reconfigure && \
            ${CMAKE_COMMAND} -E echo "All verification checks passed!"
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        VERBATIM
        DEPENDS all test run_test_suite install
    )
    
    # Add timeout to verification target
    set_property(TARGET check PROPERTY
        TIMEOUT ${VERIFICATION_TIMEOUT}
    )
    
    # Set output for check target
    set(CMAKE_VERIFICATION_OUTPUT "${CMAKE_BINARY_DIR}/verification.log")
endfunction()

# ============================================================================
# Verification Steps
# ============================================================================

function(run_verification)
    message(STATUS "Running verification checks...")
    
    local verification_result=0
    
    # Step 1: Compile all sources
    message(STATUS "Step 1/5: Compiling all sources...")
    if(NOT CMAKE_BUILD_TYPE STREQUAL "Clean")
        add_custom_target(compile_check
            COMMAND ${CMAKE_COMMAND} --build "${CMAKE_BINARY_DIR}" --config ${CMAKE_BUILD_TYPE}
            WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
            VERBATIM
        )
    endif()
    
    # Step 2: Run all tests
    message(STATUS "Step 2/5: Running all tests...")
    add_custom_target(run_test_suite
        COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        VERBATIM
    )
    
    # Step 3: Validate installation
    message(STATUS "Step 3/5: Validating installation...")
    add_custom_target(validate_install
        COMMAND ${CMAKE_COMMAND} --build "${CMAKE_BINARY_DIR}" --target install
            --config ${CMAKE_BUILD_TYPE}
            --prefix "${CMAKE_BINARY_DIR}/check_install"
            --default-directory
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        VERBATIM
    )
    
    # Step 4: Reconfigure
    message(STATUS "Step 4/5: Reconfiguring build...")
    add_custom_target(reconfigure
        COMMAND ${CMAKE_COMMAND} --reconfigure-gui
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        VERBATIM
    )
    
    # Step 5: Report summary
    message(STATUS "Step 5/5: Generating verification report...")
    add_custom_target(report
        COMMAND ${CMAKE_COMMAND} -E echo "Verification Report:"
            && ${CMAKE_COMMAND} -E echo "  - Build Status: ${BUILD_STATUS}"
            && ${CMAKE_COMMAND} -E echo "  - Test Status: ${TEST_STATUS}"
            && ${CMAKE_COMMAND} -E echo "  - Install Status: ${INSTALL_STATUS}"
            && ${CMAKE_COMMAND} -E echo "  - Overall Status: ${OVERALL_STATUS}"
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        VERBATIM
    )
    
    message(STATUS "Verification configuration completed.")
endfunction()

# ============================================================================
# Main Execution
# ============================================================================

configure_verification()
run_verification()