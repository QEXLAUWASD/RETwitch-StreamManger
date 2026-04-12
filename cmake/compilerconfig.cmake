# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (c) 2024-2025 CMake Common Modules
#
# Compiler Detection and Configuration
#
# This module handles compiler detection, validation, and configuration.

include_guard(GLOBAL)

# ============================================================================
# Compiler Detection and Validation
# ============================================================================

function(detect_and_validate_compiler)
    # Detect compiler
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        set(COMPILER "GCC" CACHE STRING "Detected compiler: GCC")
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        set(COMPILER "Clang" CACHE STRING "Detected compiler: Clang")
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        set(COMPILER "MSVC" CACHE STRING "Detected compiler: MSVC")
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
        set(COMPILER "AppleClang" CACHE STRING "Detected compiler: AppleClang")
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Intel")
        set(COMPILER "Intel" CACHE STRING "Detected compiler: Intel")
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "SunPro")
        set(COMPILER "SunPro" CACHE STRING "Detected compiler: SunPro")
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "PGI")
        set(COMPILER "PGI" CACHE STRING "Detected compiler: PGI")
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "BORLAND")
        set(COMPILER "BORLAND" CACHE STRING "Detected compiler: BORLAND")
    else()
        set(COMPILER "UNKNOWN" CACHE STRING "Detected compiler: UNKNOWN")
    endif()
    
    message(STATUS "Detected compiler: ${COMPILER}")
    
    # Validate compiler
    validate_compiler(${COMPILER})
endfunction()

# ============================================================================
# Compiler Validation
# ============================================================================

function(validate_compiler compiler)
    message(STATUS "Validating ${compiler} compiler...")
    
    if(compiler STREQUAL "UNKNOWN")
        message(FATAL_ERROR 
            "Unsupported compiler detected: ${compiler}. "
            "Please install a supported compiler (GCC 9+, Clang 10+, MSVC 2019+) or "
            "set CMAKE_CXX_COMPILER to point to a valid compiler.")
    endif()
    
    # GCC-specific validation
    if(compiler STREQUAL "GCC")
        get_property(CMAKE_CXX_COMPILER_VERSION property GLOBAL)
        string(REGEX MATCH "^[0-9]+" _major_version "${CMAKE_CXX_COMPILER_VERSION}")
        
        if(_major_version VERSION_LESS 9)
            message(FATAL_ERROR 
                "GCC ${CMAKE_CXX_COMPILER_VERSION} is too old. "
                "Minimum required version: GCC 9.0.0 or later.")
        endif()
        
        message(STATUS "GCC ${CMAKE_CXX_COMPILER_VERSION} validated.")
    
    # Clang-specific validation
    elseif(compiler STREQUAL "Clang" OR compiler STREQUAL "AppleClang")
        get_property(CMAKE_CXX_COMPILER_VERSION property GLOBAL)
        string(REGEX MATCH "^[0-9]+" _major_version "${CMAKE_CXX_COMPILER_VERSION}")
        
        if(_major_version VERSION_LESS 10)
            message(FATAL_ERROR 
                "Clang ${CMAKE_CXX_COMPILER_VERSION} is too old. "
                "Minimum required version: Clang 10.0.0 or later.")
        endif()
        
        message(STATUS "Clang ${CMAKE_CXX_COMPILER_VERSION} validated.")
    
    # MSVC-specific validation
    elseif(compiler STREQUAL "MSVC")
        # MSVC version mapping
        if(MSVC_VERSION VERSION_LESS 1929)
            message(WARNING 
                "MSVC ${MSVC_VERSION} may have limited C++17 support. "
                "Recommended: MSVC 2019 (19.29+) or later.")
        endif()
        
        message(STATUS "MSVC ${MSVC_VERSION} validated.")
    
    # Intel compiler
    elseif(compiler STREQUAL "Intel")
        message(STATUS "Intel compiler detected. C++17 support may vary.")
    
    else()
        message(WARNING 
            "${compiler} compiler detected. Some features may not be fully supported.")
    endif()
endfunction()

# ============================================================================
# Compiler Flags Configuration
# ============================================================================

function(configure_compiler_flags)
    # -----------------------------------------------------------------------------
    # C++ Flags
    # -----------------------------------------------------------------------------
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR 
       CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR
       CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
        
        # Base flags
        if(STRICT_WARNINGS)
            append_flag_list(CMAKE_CXX_FLAGS "-Wall" "-Wextra" "-Wpedantic" "-Werror=return-type")
        endif()
        
        if(ENABLE_OPTIMIZATION_HINTS)
            if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
                append_flag_list(CMAKE_CXX_FLAGS "-Og" "-fno-strict-aliasing")
            elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
                append_flag_list(CMAKE_CXX_FLAGS "-Og" "-fno-strict-aliasing")
            endif()
        endif()
        
        # Code generation checks
        if(ENABLE_CODE_GENERATION_CHECKS)
            append_flag_list(CMAKE_CXX_FLAGS "-Wno-error=pessimizing-move" "-Wno-error=maybe-uninitialized")
        endif()
    
    # MSVC flags
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        # Base flags
        if(STRICT_WARNINGS)
            append_flag_list(CMAKE_CXX_FLAGS "/W4" "/WX" "/permissive-" "/Zc:__cplusplus")
        endif()
        
        if(ENABLE_OPTIMIZATION_HINTS)
            append_flag_list(CMAKE_CXX_FLAGS "/Od" "/Zc:strictStrings" "/Zc:forScope")
        endif()
    endif()
    
    # -----------------------------------------------------------------------------
    # C Flags (for C programs)
    # -----------------------------------------------------------------------------
    if(CMAKE_C_COMPILER_ID STREQUAL "GNU" OR 
       CMAKE_C_COMPILER_ID STREQUAL "Clang" OR
       CMAKE_C_COMPILER_ID STREQUAL "AppleClang")
        
        if(STRICT_WARNINGS)
            append_flag_list(CMAKE_C_FLAGS "-Wall" "-Wextra" "-Wpedantic")
        endif()
        
        if(ENABLE_OPTIMIZATION_HINTS)
            append_flag_list(CMAKE_C_FLAGS "-Og" "-fno-strict-aliasing")
        endif()
    elseif(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
        if(STRICT_WARNINGS)
            append_flag_list(CMAKE_C_FLAGS "/W4" "/WX")
        endif()
        
        if(ENABLE_OPTIMIZATION_HINTS)
            append_flag_list(CMAKE_C_FLAGS "/Od")
        endif()
    endif() # End of C flags if/elseif block
endfunction()

# ============================================================================
# Helper Functions
# ============================================================================

function(append_flag_list flags)
    foreach(flag ${ARGV})
        string(APPEND CMAKE_CXX_FLAGS " ${flag}")
        string(APPEND CMAKE_C_FLAGS " ${flag}")
    endforeach()
endfunction()

# ============================================================================
# Final Validation
# ============================================================================

function(configure_compiler)
    message(STATUS "Configuring compiler...")
    
    # Detect and validate
    detect_and_validate_compiler()
    
    # Configure flags
    configure_compiler_flags()
    
    message(STATUS "Compiler configuration completed successfully.")
endfunction()

# ============================================================================
# Main Execution
# ============================================================================

configure_compiler()