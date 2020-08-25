cmake_minimum_required(VERSION 3.14)
project(OSGFM)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17")

install(
  EXPORT OSGFMTargets
  DESTINATION lib/cmake/OSGFM)

include(CMakePackageConfigHelpers)

configure_package_config_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/cmake/OSGFMConfig.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/OSGFMConfig.cmake
  INSTALL_DESTINATION lib/cmake/OSGFM)

add_subdirectory(examples)
add_subdirectory(include)
add_subdirectory(lib)

install(
  FILES ${CMAKE_CURRENT_BINARY_DIR}/OSGFMConfig.cmake
  DESTINATION lib/cmake/OSGFM)
