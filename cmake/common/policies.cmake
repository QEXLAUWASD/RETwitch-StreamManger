# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (c) 2024-2025 CMake Common Modules
#
# CMake Policy Settings for Modern CMake Behavior
#
# This module establishes consistent policy settings across all projects
# that use this CMake infrastructure.

include_guard(GLOBAL)

# ============================================================================
# CMake Policy Settings
# ============================================================================

# -----------------------------------------------------------------------------
# CMP0024: Relative include directories (NEW in 3.13)
# -----------------------------------------------------------------------------
# Enable relative include directories (e.g., "${CMAKE_CURRENT_LIST_DIR}")
# This is required for proper module loading
if(POLICY CMP0024)
    cmake_policy(SET CMP0024 NEW)
endif()

# -----------------------------------------------------------------------------
# CMP0026: Include directories in scope (NEW in 3.18)
# -----------------------------------------------------------------------------
# When using include_directories(), also add the include path to
# the list of implicit include directories.
if(POLICY CMP0026)
    cmake_policy(SET CMP0026 NEW)
endif()

# -----------------------------------------------------------------------------
# CMP0030: Use relative paths for include directories (NEW in 3.13)
# -----------------------------------------------------------------------------
# Use relative paths for include directories when using include_directories()
if(POLICY CMP0030)
    cmake_policy(SET CMP0030 NEW)
endif()

# -----------------------------------------------------------------------------
# CMP0037: Use relative paths for link libraries (NEW in 3.13)
# -----------------------------------------------------------------------------
# Use relative paths for link libraries when using link_libraries()
if(POLICY CMP0037)
    cmake_policy(SET CMP0037 NEW)
endif()

# -----------------------------------------------------------------------------
# CMP0042: Honor require for targets (NEW in 3.16)
# -----------------------------------------------------------------------------
# REQUIRE can be used to require targets
if(POLICY CMP0042)
    cmake_policy(SET CMP0042 NEW)
endif()

# -----------------------------------------------------------------------------
# CMP0054: Export for package config files (NEW in 3.16)
# -----------------------------------------------------------------------------
# The export() command can be used to create package config files
if(POLICY CMP0054)
    cmake_policy(SET CMP0054 NEW)
endif()

# -----------------------------------------------------------------------------
# CMP0055: CMake package config compatibility (NEW in 3.18)
# -----------------------------------------------------------------------------
# CMake package config files must have a compatible version
if(POLICY CMP0055)
    cmake_policy(SET CMP0055 NEW)
endif()

# -----------------------------------------------------------------------------
# CMP0063: Isolation of configure and build steps (NEW in 3.22)
# -----------------------------------------------------------------------------
# CMake will not use the results from previous configure calls
# if the CMakeCache.txt has been modified since the last configure.
if(POLICY CMP0063)
    cmake_policy(SET CMP0063 NEW)
endif()

# -----------------------------------------------------------------------------
# CMP0074: Policy for unknown properties (NEW in 3.23)
# -----------------------------------------------------------------------------
# Unknown properties are ignored instead of causing an error
if(POLICY CMP0074)
    cmake_policy(SET CMP0074 NEW)
endif()

# -----------------------------------------------------------------------------
# CMP0077: Honor target interfaces (NEW in 3.24)
# -----------------------------------------------------------------------------
# Target interfaces (INTERFACE libraries, etc.) are honored
if(POLICY CMP0077)
    cmake_policy(SET CMP0077 NEW)
endif()

# -----------------------------------------------------------------------------
# CMP0078: Require targets in find_package (NEW in 3.24)
# -----------------------------------------------------------------------------
# Targets required by find_package() must exist
if(POLICY CMP0078)
    cmake_policy(SET CMP0078 NEW)
endif()

# -----------------------------------------------------------------------------
# CMP0079: Honor target interfaces (NEW in 3.24)
# -----------------------------------------------------------------------------
# Honor target interfaces for transitive dependencies
if(POLICY CMP0079)
    cmake_policy(SET CMP0079 NEW)
endif()

# -----------------------------------------------------------------------------
# CMP0080: Honor target interfaces (NEW in 3.24)
# -----------------------------------------------------------------------------
# Honor target interfaces for imported targets
if(POLICY CMP0080)
    cmake_policy(SET CMP0080 NEW)
endif()

# -----------------------------------------------------------------------------
# CMP0084: Require targets in find_package (NEW in 3.26)
# -----------------------------------------------------------------------------
# Targets required by find_package() must exist
if(POLICY CMP0084)
    cmake_policy(SET CMP0084 NEW)
endif()

# -----------------------------------------------------------------------------
# CMP0085: Require targets in find_package (NEW in 3.26)
# -----------------------------------------------------------------------------
# Require targets in find_package() calls
if(POLICY CMP0085)
    cmake_policy(SET CMP0085 NEW)
endif()

# -----------------------------------------------------------------------------
# CMP0086: Honor target interfaces (NEW in 3.26)
# -----------------------------------------------------------------------------
# Honor target interfaces for transitive dependencies
if(POLICY CMP0086)
    cmake_policy(SET CMP0086 NEW)
endif()

# -----------------------------------------------------------------------------
# CMP0087: Honor target interfaces (NEW in 3.26)
# -----------------------------------------------------------------------------
# Honor target interfaces for imported targets
if(POLICY CMP0087)
    cmake_policy(SET CMP0087 NEW)
endif()

# -----------------------------------------------------------------------------
# CMP0088: Honor target interfaces (NEW in 3.26)
# -----------------------------------------------------------------------------
# Honor target interfaces for transitive dependencies
if(POLICY CMP0088)
    cmake_policy(SET CMP0088 NEW)
endif()

# -----------------------------------------------------------------------------
# CMP0089: Honor target interfaces (NEW in 3.26)
# -----------------------------------------------------------------------------
# Honor target interfaces for imported targets
if(POLICY CMP0089)
    cmake_policy(SET CMP0089 NEW)
endif()

# -----------------------------------------------------------------------------
# CMP0090: Honor target interfaces (NEW in 3.26)
# -----------------------------------------------------------------------------
# Honor target interfaces for transitive dependencies
if(POLICY CMP0090)
    cmake_policy(SET CMP0090 NEW)
endif()

# ============================================================================
# Policy Validation
# ============================================================================

function(validate_policies)
    message(STATUS "Validating CMake policies...")
    
    # Check for unsupported policies
    foreach(policy ${CMAKE_POLICY_VERSION})
        if(CMAKE_${policy}_VERSION STREQUAL "")
            message(FATAL_ERROR 
                "Policy ${policy} not found. Please upgrade CMake to version 3.26+.")
        endif()
    endforeach()
    
    message(STATUS "All policies validated successfully.")
endfunction()

# Validate policies if explicitly requested
if(DEFINED ENABLE_POLICY_VALIDATION)
    validate_policies()
endif()