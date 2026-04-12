# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (c) 2024-2025 CMake Common Modules
#
# Windows Platform Support
#
# This module configures Windows-specific build settings.

include_guard(GLOBAL)

# ============================================================================
# Windows Platform Detection
# ============================================================================

if(WIN32)
    message(STATUS "Configuring Windows platform...")
    
    # -----------------------------------------------------------------------------
    # MSVC Runtime Library Consistency
    # -----------------------------------------------------------------------------
    # Ensure consistent runtime library across all targets
    if(MSVC)
        # Use static runtime for consistent behavior
        if(BUILD_SHARED_LIBS)
            string(APPEND CMAKE_CXX_FLAGS " /MT")
            string(APPEND CMAKE_C_FLAGS " /MT")
        else()
            string(APPEND CMAKE_CXX_FLAGS " /MD")
            string(APPEND CMAKE_C_FLAGS " /MD")
        endif()
        
        message(STATUS "MSVC runtime: ${CMAKE_CXX_FLAGS}")
    endif()
    
    # -----------------------------------------------------------------------------
    # Windows-Specific Compiler Flags
    # -----------------------------------------------------------------------------
    if(MSVC)
        # Base warnings
        string(APPEND CMAKE_CXX_FLAGS " /W4 /WX- /permissive- /Zc:__cplusplus /Zc:forScope /Zc:strictStrings /Zc:throwingNew /Zc:twoPhase- /utf-8 /std:c++17")
        
        # Debug flags
        if(CMAKE_BUILD_TYPE STREQUAL "Debug")
            string(APPEND CMAKE_CXX_FLAGS " /Od /Zi /FS /FS")
        endif()
        
        # Release flags
        if(CMAKE_BUILD_TYPE STREQUAL "Release")
            string(APPEND CMAKE_CXX_FLAGS " /O2 /Ob2 /Oi /Ot /GL /Gy /Zi /LTCG /GL /EHsc")
        endif()
        
        # RelWithDebInfo flags
        if(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
            string(APPEND CMAKE_CXX_FLAGS " /O2 /Zi /FS /GL /Gy /Zi /EHsc")
        endif()
        
        # MinSizeRel flags
        if(CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
            string(APPEND CMAKE_CXX_FLAGS " /O1 /GL /Gy /Zi")
        endif()
        
        # Security hardening
        string(APPEND CMAKE_CXX_FLAGS " /Gy /GL /DYNAMICBASE /SAFESEH /NXCOMPAT /TUNE")
        
        message(STATUS "Windows compiler flags configured")
    endif()
    
    # -----------------------------------------------------------------------------
    # Windows SDK and Platform Tools
    # -----------------------------------------------------------------------------
    if(WIN32 AND CMAKE_GENERATOR MATCHES "Visual Studio")
        # Determine minimum Windows version
        if(NOT DEFINED CMAKE_WINDOWS_TARGET_PLATFORM_MIN_VERSION)
            set(CMAKE_WINDOWS_TARGET_PLATFORM_MIN_VERSION "10.0.17763.0" CACHE STRING "Minimum Windows version")
        endif()
        
        message(STATUS "Minimum Windows version: ${CMAKE_WINDOWS_TARGET_PLATFORM_MIN_VERSION}")
    endif()
    
    # -----------------------------------------------------------------------------
    # RPATH Configuration for Windows
    # -----------------------------------------------------------------------------
    # Windows doesn't use RPATH, but we set runtime library search paths
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
    
    # -----------------------------------------------------------------------------
    # Windows-Specific Installation Paths
    # -----------------------------------------------------------------------------
    set(CMAKE_INSTALL_BINDIR "bin")
    set(CMAKE_INSTALL_LIBDIR "lib")
    set(CMAKE_INSTALL_INCLUDEDIR "include")
    
    # -----------------------------------------------------------------------------
    # Windows-Specific Build Options
    # -----------------------------------------------------------------------------
    # Enable PDB generation for debugging
    set(CMAKE_MSVC_DEBUG_INFORMATION_FORMAT "ProgramDatabase" CACHE STRING "Debug information format")
    
    # Enable whole program optimization in release
    if(CMAKE_BUILD_TYPE STREQUAL "Release")
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
    endif()
    
    # -----------------------------------------------------------------------------
    # Windows-Specific Linker Flags
    # -----------------------------------------------------------------------------
    if(MSVC)
        # Base linker flags
        string(APPEND CMAKE_EXE_LINKER_FLAGS " /DEBUG /INCREMENTAL:DEFAULT /SUBSYSTEM:CONSOLE")
        
        # Release linker flags
        if(CMAKE_BUILD_TYPE STREQUAL "Release")
            string(APPEND CMAKE_EXE_LINKER_FLAGS " /LTCG:FULL /OPT:REF /OPT:ICF /RELEASE /NXCOMPAT")
        endif()
        
        # Debug linker flags
        if(CMAKE_BUILD_TYPE STREQUAL "Debug")
            string(APPEND CMAKE_EXE_LINKER_FLAGS " /DEBUG:FASTLINK /INCREMENTAL:FULL")
        endif()
        
        # RelWithDebInfo linker flags
        if(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
            string(APPEND CMAKE_EXE_LINKER_FLAGS " /DEBUG:FASTLINK /INCREMENTAL:FULL /OPT:REF")
        endif()
        
        message(STATUS "Windows linker flags configured")
    endif()
    
    # -----------------------------------------------------------------------------
    # Windows-Specific Environment Setup
    # -----------------------------------------------------------------------------
    # Set environment variables for the build
    set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)
    
    message(STATUS "Windows platform configuration completed.")
endif()

# ============================================================================
# Cross-Compilation Support
# ============================================================================

if(CMAKE_CROSSCOMPILING)
    message(STATUS "Cross-compilation enabled...")
    
    # Propagate toolchain variables
    if(DEFINED CMAKE_CXX_COMPILER)
        message(STATUS "Target compiler: ${CMAKE_CXX_COMPILER}")
    endif()
    
    if(DEFINED CMAKE_C_COMPILER)
        message(STATUS "Target C compiler: ${CMAKE_C_COMPILER}")
    endif()
    
    if(DEFINED CMAKE_SYSTEM_NAME)
        message(STATUS "Target system: ${CMAKE_SYSTEM_NAME}")
    endif()
endif()