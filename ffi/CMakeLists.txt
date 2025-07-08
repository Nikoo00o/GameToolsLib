# top level ffi cmake file that creates the project and library files with the variables that are added in sub directories
# only the CMakeListst.txt in code and sub folders of code have to be modified!
# For changes in build cmake files search for: "# --> FFI"
cmake_minimum_required(VERSION 3.10 FATAL_ERROR)

project(ffi_api VERSION 1.0.0 LANGUAGES CXX C) # important: must be same as FFI_LIB_NAME var in code!
message("building ${PROJECT_NAME}")

add_subdirectory("code")
set(FFI_LIB_NAME "${FFI_LIB_NAME}" PARENT_SCOPE)
set (FFI_SourceFiles ${FFI_SourceFiles} PARENT_SCOPE)
set (FFI_HeaderFiles ${FFI_HeaderFiles} PARENT_SCOPE)

add_library(${PROJECT_NAME} SHARED ${FFI_SourceFiles})

target_link_libraries(${PROJECT_NAME} PUBLIC m)
set_property(TARGET ${PROJECT_NAME} PROPERTY VS_DPI_AWARE "PerMonitor")

set_target_properties(${PROJECT_NAME} PROPERTIES
        PUBLIC_HEADER ${FFI_HeaderFiles}
        VERSION ${PROJECT_VERSION}
        SOVERSION 1
        OUTPUT_NAME ${PROJECT_NAME}
        XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "TODO_Hex_Identity_ID_Goes_Here"
)





