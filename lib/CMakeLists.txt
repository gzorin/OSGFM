include_directories(
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_SOURCE_DIR}/include)

add_library(OSGFM STATIC
    OSGFM.mm)

target_compile_features(OSGFM PRIVATE cxx_std_17)

target_link_libraries(OSGFM
    "-framework Cocoa" "-framework Metal" "-framework MetalKit")

install(
  TARGETS OSGFM
  EXPORT OSGFMTargets
  ARCHIVE
  DESTINATION lib)