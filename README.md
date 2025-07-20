# GameToolsLib

- A Collection of Tools to interact with a game to create useful community tools 
- These should only access the Game in a legal/allowed way via image recognition and reading log files 
  - No memory reading, or writing should be done, because accessing memory is not welcome by most publishers  

## Supported Platforms

- IMPORTANT: currently only **windows** is supported and no other platform! 

## Assets

- the pubspec files of the library, but also all applications must have "assets/" under the "-assets" category
  - and under that you should at least have "assets/images/" and "assets/locales/" 
- when building the app the assets will be at two locations: "data/flutter_assets/assets/" and 
  "data/flutter_assets/packages/game_tools_lib/assets"

### Translation files 

- after declaring your supported languages in the config, you have to create a translation file (like "en.json") for 
  each language and put them into "assets/locales" of your project 
- the default game tools lib only contains one "en.json" with some basic keys that will be merged with your english 
  translation file! (you have to manually copy and translate the keys for other languages!!!!)

## Build

### Prerequisites 

- Up To Date Cmake Version https://cmake.org/download/ 
- Flutter/Dart https://docs.flutter.dev/install/manual with android studio (or visual studio code)
- Up To Date Visual Studio Version (Current 2022) with newest Windows 10/11 SDK downloaded in Visual Studio 
  Installer

### Build Required Dlls

- On windows copy microsoft dll files into exe dir: msvcp140.dll, vcruntime140.dll, vcruntime140_1.dll

### Running Tests

- Running `flutter test` inside of the root library directory needs to have the native code dll put into 
  `build/test/game_tools_lib_plugin.dll`
- You can get the dll by just starting the example project, or any other application in debug mode and then copying 
  the file out of the `example\build\windows\x64\runner\Debug` directory
  - cmd: `copy .\example\build\windows\x64\runner\Debug\game_tools_lib_plugin.dll .\build\test\`
- IMPORTANT: the exact name of the lib depends on the platform you are using! 
- Now for opencv and its `dartcv.dll` (or however its called on your platform), you have to set the environment 
  variable`DARTCV_LIB_PATH` to a path where you have stored an already build copy of the library 
  - of course you can also use the `build/test` directory for that! 
  - IMPORTANT: you also have to copy the OpenCV lib dependencies in the same folder (avcodec-61, avdevice-61, 
    avfilter-10, avformat-61, avutil-59, swresample-5, swscale-8)
- REMEMBER TO update all of those libraries when a new opencv version is released! 
- AND ALSO copy the game_tools_lib_plugin library again when you modify the native C/C++ code!!! 

#### Native Tests

- The native tests that need to interact with a window are moved into `example/integration_test` to be able to work 
  and they also open a test window app

### OpenCV build

- its best to set the environment variable "DARTCV_CACHE_DIR" so that opencv_dart can be cached
- see https://pub.dev/packages/opencv_dart
- Could lead to errors if vcpkg is installed with another version of opencv 

### Building FFI Native Code 

- Currently only configured for windows and not tested on linux (macOS would also need Signing in CMakeLists.txt)
- mac would also need additional steps: 
  - in Xcode(macos/Runner.xcodeproj) create new group without folder called ffi
  - then add the cpp source files to that folder (same for ios)
- android would need an externalNativeBuild  with cmake section and then "path" "to"
- but xcode and android could also be different for a plugin/package instead of an app! 

#### If the native code would be used directly inside of an app and not the plugin

- then for linux the linux/CMakeLists.txt would have to be modified with the following:
- first above "# === Installation ==="
```cmake
# --> FFI Setup.
message("Adding ${CMAKE_CURRENT_SOURCE_DIR}/../ffi")
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../ffi" "${CMAKE_CURRENT_BINARY_DIR}/ffi")
```
- then at the end of the file: 
```cmake
# --> FFI Install
message("Installing ${PROJECT_BINARY_DIR}/ffi/lib${FFI_LIB_NAME}.so")
install(FILES ${PROJECT_BINARY_DIR}/ffi/lib${FFI_LIB_NAME}.so DESTINATION "${INSTALL_BUNDLE_LIB_DIR}" COMPONENT Runtime)
```

- and for windows the windows/runner/CmakeLists.txt has to be modified with the following:
- at the end of the file: 
```cmake
# --> FFI Setup and Install.
message("Adding ${CMAKE_CURRENT_SOURCE_DIR}/../../ffi/code")
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../../ffi/code" "${CMAKE_CURRENT_BINARY_DIR}/ffi_code")
message("Adding ${FFI_LIB_NAME} with ${FFI_SourceFiles}")
add_library(${FFI_LIB_NAME} SHARED ${FFI_SourceFiles})
```

- another difference would be in the "ffi_exports.def" file at the top the name would not be "game_tools_lib_plugin" 
  like the package, but instead it would be the name of the cmake project (the top level cmake file in ffi is 
  currently not used in this way)

- but in this case for a plugin, in both cases the platform specific CMakeLists.txt was modified with: 
- before the add_library call with the "PLUGIN_SOURCES"
```cmake 
# --> FFI Setup and Install.
message("Adding ${CMAKE_CURRENT_SOURCE_DIR}/../ffi/code")
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../ffi/code" "${CMAKE_CURRENT_BINARY_DIR}/ffi_code")
message("Adding ${FFI_LIB_NAME} with ${FFI_SourceFiles}")
set (PLUGIN_SOURCES ${PLUGIN_SOURCES} ${FFI_SourceFiles})
```
