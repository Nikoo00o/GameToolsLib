cmake_minimum_required(VERSION 3.10 FATAL_ERROR)
set(FFI_LIB_NAME "ffi_api" PARENT_SCOPE) # used in the build cmake files for the platforms (must be same as project name!)

# TODO: add all sub directories here with their own cmake files to add the sources
add_subdirectory("native_window")

# TODO: remember to modify "ffi_exports.def" to export all public functions from all headers!
# Also those functions must be marked with EXPORT (and the exports.h header should be included)
# IMPORTANT: the name at the top of ffi_exports.def depends on if this is used as a plugin, or directly inside of an app
set (FFI_SourceFiles ${FFI_SourceFiles}
        ${CMAKE_CURRENT_SOURCE_DIR}/ffi_exports.def
        PARENT_SCOPE
)

set (FFI_HeaderFiles ${FFI_HeaderFiles}
        ${CMAKE_CURRENT_SOURCE_DIR}/exports.h
        PARENT_SCOPE
)

message("loaded ffi sources ${FFI_SourceFiles}")