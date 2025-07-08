# cmake project for the native window ffi code (needs to add all sources here)
# remember to add exports in the top level .def file for the .h files!
cmake_minimum_required (VERSION 3.10.0)
set (FFI_SourceFiles ${FFI_SourceFiles}
        ${CMAKE_CURRENT_SOURCE_DIR}/native_window.cpp
        PARENT_SCOPE
)

set (FFI_HeaderFiles ${FFI_HeaderFiles}
        ${CMAKE_CURRENT_SOURCE_DIR}/native_window.hpp
        PARENT_SCOPE
)