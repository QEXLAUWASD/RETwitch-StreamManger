cmake_minimum_required(VERSION 3.28...3.30)

include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/common/bootstrap.cmake" NO_POLICY_SCOPE)

project(${_name} VERSION ${_version})

option(ENABLE_FRONTEND_API "Use obs-frontend-api for UI functionality" ON)
option(ENABLE_QT "Use Qt functionality" ON)

include(compilerconfig)
include(defaults)
include(helpers)

add_library(${CMAKE_PROJECT_NAME} MODULE)

find_package(libobs REQUIRED)
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE OBS::libobs)

if(ENABLE_FRONTEND_API)
  find_package(obs-frontend-api REQUIRED)
  target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE OBS::obs-frontend-api)
endif()

if(ENABLE_QT)
  find_package(Qt6 COMPONENTS Widgets Core Network)
  target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE Qt6::Core Qt6::Widgets Qt6::Network)
  target_compile_options(
    ${CMAKE_PROJECT_NAME}
    PRIVATE $<$<C_COMPILER_ID:Clang,AppleClang>:-Wno-quoted-include-in-framework-header -Wno-comma>
  )
  set_target_properties(
    ${CMAKE_PROJECT_NAME}
    PROPERTIES AUTOMOC ON AUTOUIC ON AUTORCC ON
  )
endif()

target_sources(
  ${CMAKE_PROJECT_NAME}
  PRIVATE src/plugin-main.cpp
          src/AppState.hpp
          src/ConfigStore.hpp
          src/ConfigStore.cpp
          src/ProcessMonitor.hpp
          src/ProcessMonitor.cpp
          src/TwitchClient.hpp
          src/TwitchClient.cpp
          src/TwitchAutoTitleDialog.hpp
          src/TwitchAutoTitleDialog.cpp)

if(OS_WINDOWS)
  target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE psapi)

  # Ship the Qt TLS backend (Schannel) alongside the plugin so HTTPS works.
  find_file(
    QT_SCHANNEL_DLL
    NAMES qschannelbackend.dll
    PATHS "${Qt6_DIR}/../../../plugins/tls"
          "${Qt6Core_DIR}/../../../plugins/tls"
    NO_DEFAULT_PATH)
  if(QT_SCHANNEL_DLL)
    add_custom_command(
      TARGET ${CMAKE_PROJECT_NAME} POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E make_directory
              "$<TARGET_FILE_DIR:${CMAKE_PROJECT_NAME}>/tls"
      COMMAND ${CMAKE_COMMAND} -E copy_if_different "${QT_SCHANNEL_DLL}"
              "$<TARGET_FILE_DIR:${CMAKE_PROJECT_NAME}>/tls/qschannelbackend.dll"
      COMMENT "Copying Qt TLS plugin (qschannelbackend.dll)")
    install(
      FILES "${QT_SCHANNEL_DLL}"
      DESTINATION "obs-plugins/64bit/tls"
      COMPONENT Runtime)
  else()
    message(WARNING "qschannelbackend.dll not found — HTTPS may not work")
  endif()
endif()

set_target_properties_plugin(${CMAKE_PROJECT_NAME} PROPERTIES OUTPUT_NAME ${_name})
