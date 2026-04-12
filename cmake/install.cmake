# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (c) 2024-2025 CMake Common Modules
#
# Installation Rules and Configuration
#
# This module configures proper installation rules with export targets.

include_guard(GLOBAL)

# ============================================================================
# Installation Configuration
# ============================================================================

# Use GNUInstallDirs for standard installation directories
include(GNUInstallDirs)

# Set installation prefix if not already set
if(NOT CMAKE_INSTALL_PREFIX)
    set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/install" CACHE PATH "Installation prefix" FORCE)
endif()

# ============================================================================
# Installation Variables
# ============================================================================

# Installation components
set(INSTALL_COMPONENTS
    "runtime"      "Runtime files"
    "development"  "Development files"
    "documentation" "Documentation"
    CACHE STRING "Installation components")

# Version information
set(INSTALL_VERSION "${_version}")
set(INSTALL_PACKAGE_NAME "${_name}")
set(INSTALL_PACKAGE_DESCRIPTION "${_description}")

# ============================================================================
# Installation Functions
# ============================================================================

function(configure_installation)
    message(STATUS "Configuring installation...")
    
    # -----------------------------------------------------------------------------
    # Installation Directories
    # -----------------------------------------------------------------------------
    set(CMAKE_INSTALL_BINDIR "${CMAKE_INSTALL_PREFIX}/bin")
    set(CMAKE_INSTALL_LIBDIR "${CMAKE_INSTALL_PREFIX}/lib")
    set(CMAKE_INSTALL_INCLUDEDIR "${CMAKE_INSTALL_PREFIX}/include")
    set(CMAKE_INSTALL_DATADIR "${CMAKE_INSTALL_PREFIX}/share")
    set(CMAKE_INSTALL_DOCDIR "${CMAKE_INSTALL_DATADIR}/doc/${INSTALL_PACKAGE_NAME}")
    
    # -----------------------------------------------------------------------------
    # Runtime Library Path
    # -----------------------------------------------------------------------------
    set(CMAKE_INSTALL_RPATH "$ORIGIN")
    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH ON)
    
    # -----------------------------------------------------------------------------
    # Export Targets
    # -----------------------------------------------------------------------------
    include(CMakePackageConfigHelpers)
    
    # Generate config file
    configure_package_config_file(
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake/${INSTALL_PACKAGE_NAME}Config.cmake.in"
        "${CMAKE_BINARY_DIR}/${INSTALL_PACKAGE_NAME}Config.cmake"
        INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${INSTALL_PACKAGE_NAME}"
        PATH_VARS CMAKE_INSTALL_LIBDIR
    )
    
    # Generate version file
    write_basic_package_version_file(
        "${CMAKE_BINARY_DIR}/${INSTALL_PACKAGE_NAME}ConfigVersion.cmake"
        VERSION ${INSTALL_VERSION}
        COMPATIBILITY SameMajorVersion
    )
    
    # Install config files
    install(FILES
        "${CMAKE_BINARY_DIR}/${INSTALL_PACKAGE_NAME}Config.cmake"
        "${CMAKE_BINARY_DIR}/${INSTALL_PACKAGE_NAME}ConfigVersion.cmake"
        DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${INSTALL_PACKAGE_NAME}"
    )
    
    # -----------------------------------------------------------------------------
    # Export Targets
    # -----------------------------------------------------------------------------
    export(EXPORT "${INSTALL_PACKAGE_NAME}Targets"
        FILE "${CMAKE_BINARY_DIR}/${INSTALL_PACKAGE_NAME}Targets.cmake"
        NAMESPACE "${INSTALL_PACKAGE_NAME}::"
    )
    
    install(EXPORT "${INSTALL_PACKAGE_NAME}Targets"
        FILE "${INSTALL_PACKAGE_NAME}Targets.cmake"
        DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${INSTALL_PACKAGE_NAME}"
        NAMESPACE "${INSTALL_PACKAGE_NAME}::"
        COMPONENT development
    )
    
    # -----------------------------------------------------------------------------
    # pkg-config File Generation
    # -----------------------------------------------------------------------------
    configure_file(
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake/${INSTALL_PACKAGE_NAME}.pc.in"
        "${CMAKE_BINARY_DIR}/${INSTALL_PACKAGE_NAME}.pc"
        @ONLY
    )
    
    install(FILES
        "${CMAKE_BINARY_DIR}/${INSTALL_PACKAGE_NAME}.pc"
        DESTINATION "${CMAKE_INSTALL_LIBDIR}/pkgconfig"
        COMPONENT development
    )
    
    # -----------------------------------------------------------------------------
    # Header Installation
    # -----------------------------------------------------------------------------
    install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/src/"
        DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${INSTALL_PACKAGE_NAME}"
        COMPONENT development
        FILES_MATCHING PATTERN "*.hpp"
    )
    
    # -----------------------------------------------------------------------------
    # Library Installation (if any)
    # -----------------------------------------------------------------------------
    # This would be added when actual libraries are built
    
    # -----------------------------------------------------------------------------
    # Documentation Installation
    # -----------------------------------------------------------------------------
    install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/doc/"
        DESTINATION "${CMAKE_INSTALL_DOCDIR}"
        COMPONENT documentation
    )
    
    message(STATUS "Installation configuration completed.")
endfunction()

# ============================================================================
# Helper Functions
# ============================================================================

function(install_component component)
    set(INSTALL_COMPONENT "${component}" PARENT_SCOPE)
endfunction()

# ============================================================================
# Main Execution
# ============================================================================

configure_installation()