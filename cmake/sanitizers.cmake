# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (c) 2024-2025 CMake Common Modules
#
# Sanitizer Support Configuration
#
# This module enables and configures various sanitizers for debugging and testing.

include_guard(GLOBAL)

# ============================================================================
# Sanitizer Options
# ============================================================================

# AddressSanitizer
set(ENABLE_ASAN OFF CACHE BOOL "Enable AddressSanitizer (memory error detection)")

# ThreadSanitizer
set(ENABLE_TSAN OFF CACHE BOOL "Enable ThreadSanitizer (thread safety detection)")

# UndefinedBehaviorSanitizer
set(ENABLE_UBSAN OFF CACHE BOOL "Enable UndefinedBehaviorSanitizer (UB detection)")

# LeakSanitizer
set(ENABLE_LSAN OFF CACHE BOOL "Enable LeakSanitizer (memory leak detection)")

# MemorySanitizer
set(ENABLE_MSAN OFF CACHE BOOL "Enable MemorySanitizer (memory use errors)")

# HWAddressSanitizer
set(ENABLE_HWASAN OFF CACHE BOOL "Enable HardwareAddressSanitizer (fast memory error detection)")

# ============================================================================
# Sanitizer Configuration Functions
# ============================================================================

function(configure_sanitizers)
    message(STATUS "Configuring sanitizers...")
    
    # -----------------------------------------------------------------------------
    # AddressSanitizer Configuration
    # -----------------------------------------------------------------------------
    if(ENABLE_ASAN)
        if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR 
           CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR
           CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
            
            # Base flags
            append_sanitizer_flags(CMAKE_CXX_FLAGS "-fsanitize=address"
                "-fno-omit-frame-pointer"
                "-fno-sanitize-recover=all"
                "-fno-sanitize=unsigned-integer-overflow,unsigned-shift-base")
            
            # Linker flags
            append_sanitizer_flags(CMAKE_EXE_LINKER_FLAGS "-fsanitize=address")
            
            message(STATUS "AddressSanitizer enabled")
        else()
            message(FATAL_ERROR "AddressSanitizer only supported with GCC or Clang")
        endif()
    endif()
    
    # -----------------------------------------------------------------------------
    # ThreadSanitizer Configuration
    # -----------------------------------------------------------------------------
    if(ENABLE_TSAN)
        if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR 
           CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR
           CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
            
            # Base flags
            append_sanitizer_flags(CMAKE_CXX_FLAGS "-fsanitize=thread"
                "-fno-omit-frame-pointer"
                "-fno-sanitize-recover=all")
            
            # Linker flags
            append_sanitizer_flags(CMAKE_EXE_LINKER_FLAGS "-fsanitize=thread")
            
            message(STATUS "ThreadSanitizer enabled")
        else()
            message(FATAL_ERROR "ThreadSanitizer only supported with GCC or Clang")
        endif()
    endif()
    
    # -----------------------------------------------------------------------------
    # UndefinedBehaviorSanitizer Configuration
    # -----------------------------------------------------------------------------
    if(ENABLE_UBSAN)
        if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR 
           CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR
           CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
            
            # Base flags
            append_sanitizer_flags(CMAKE_CXX_FLAGS "-fsanitize=undefined"
                "-fno-omit-frame-pointer"
                "-fno-sanitize-recover=all")
            
            # Linker flags
            append_sanitizer_flags(CMAKE_EXE_LINKER_FLAGS "-fsanitize=undefined")
            
            message(STATUS "UndefinedBehaviorSanitizer enabled")
        else()
            message(FATAL_ERROR "UndefinedBehaviorSanitizer only supported with GCC or Clang")
        endif()
    endif()
    
    # -----------------------------------------------------------------------------
    # LeakSanitizer Configuration
    # -----------------------------------------------------------------------------
    if(ENABLE_LSAN)
        if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR 
           CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR
           CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
            
            # Base flags
            append_sanitizer_flags(CMAKE_CXX_FLAGS "-fsanitize=leak"
                "-fno-omit-frame-pointer")
            
            # Linker flags
            append_sanitizer_flags(CMAKE_EXE_LINKER_FLAGS "-fsanitize=leak")
            
            message(STATUS "LeakSanitizer enabled")
        else()
            message(FATAL_ERROR "LeakSanitizer only supported with GCC or Clang")
        endif()
    endif()
    
    # -----------------------------------------------------------------------------
    # MemorySanitizer Configuration
    # -----------------------------------------------------------------------------
    if(ENABLE_MSAN)
        if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR 
           CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR
           CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
            
            # Note: MSAN requires instrumented libc and libm
            append_sanitizer_flags(CMAKE_CXX_FLAGS "-fsanitize=memory"
                "-fno-omit-frame-pointer")
            
            # Linker flags
            append_sanitizer_flags(CMAKE_EXE_LINKER_FLAGS "-fsanitize=memory")
            
            message(STATUS "MemorySanitizer enabled (requires instrumented libraries)")
        else()
            message(FATAL_ERROR "MemorySanitizer only supported with GCC or Clang")
        endif()
    endif()
    
    # -----------------------------------------------------------------------------
    # HardwareAddressSanitizer Configuration
    # -----------------------------------------------------------------------------
    if(ENABLE_HWASAN)
        if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
            
            # HWASAN requires special setup and glibc 2.35+
            append_sanitizer_flags(CMAKE_CXX_FLAGS "-fsanitize=hardware"
                "-fno-omit-frame-pointer")
            
            # Linker flags
            append_sanitizer_flags(CMAKE_EXE_LINKER_FLAGS "-fsanitize=hardware")
            
            message(STATUS "HardwareAddressSanitizer enabled (requires glibc 2.35+)")
        else()
            message(WARNING "HardwareAddressSanitizer only fully supported with GCC")
        endif()
    endif()
    
    # -----------------------------------------------------------------------------
    # Combined Sanitizers
    # -----------------------------------------------------------------------------
    if(ENABLE_ASAN AND ENABLE_TSAN)
        message(FATAL_ERROR "Cannot enable both AddressSanitizer and ThreadSanitizer simultaneously")
    endif()
    
    if(ENABLE_ASAN AND ENABLE_UBSAN)
        message(WARNING "Enabling both AddressSanitizer and UBSan may cause conflicts")
    endif()
    
    message(STATUS "Sanitizer configuration completed.")
endfunction()

# ============================================================================
# Helper Functions
# ============================================================================

function(append_sanitizer_flags flags)
    foreach(flag ${ARGV})
        string(APPEND CMAKE_CXX_FLAGS " ${flag}")
        string(APPEND CMAKE_C_FLAGS " ${flag}")
    endforeach()
endfunction()

# ============================================================================
# Main Execution
# ============================================================================

configure_sanitizers()