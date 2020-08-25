include_directories(
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_SOURCE_DIR}/include)
add_definitions(${LLVM_DEFINITIONS})

# triangle
set(triangle_SOURCES triangle.mm)
add_executable(triangle ${triangle_SOURCES})

target_link_libraries(triangle OSGFM)