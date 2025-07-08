#include <windows.h>
#include "../exports.h"

#ifndef NATIVE_WINDOW_H
#define NATIVE_WINDOW_H

/// This must be called first to initialize the windowName (also resets the handle).
/// The windowID starts at 0 and has to be used for the other functions (only numbers 0 >= windowID < 100 )
/// Name Examples: "Path of Exile", "TL", "League of Legends"
/// For Default windows it will be checked if the windowName is contained in the real name of the window
/// This can be disabled by setting "alwaysMatchEqual" to true
/// For Debugging printWindowNames can be set to true (otherwise this should be false)
EXPORT bool initWindow(int windowID, const char *windowName, bool alwaysMatchEqual, bool printWindowNames);

/// initWindow must be called first
EXPORT bool isWindowOpen(int windowID);

/// initWindow must be called first
EXPORT bool hasWindowFocus(int windowID);

/// initWindow must be called first
EXPORT bool setWindowFocus(int windowID);

/// initWindow must be called first
/// The top left corner of the window is top, left (for borderless / fullscreen they are both 0)
/// width = right - left
/// height = bottom - top
EXPORT RECT getWindowBounds(int windowID);

EXPORT unsigned int getMainDisplayWidth();

EXPORT unsigned int getMainDisplayHeight();

EXPORT bool closeWindow(int windowID);

/// Used for data returned by getImageOfMainDisplay and getFullMainDisplay
EXPORT void cleanupMemory(unsigned char *data);

/// Returns a screenshot of the full main display
/// This is DPI Aware (see CMakeLists.txt)!
/// IMPORTANT: the memory management (cleanup of the returned data) must be done on the outside!!!
/// An Image can be created from the data with "cv::Mat(height, width, CV_8UC4, data);" but will not cleanup
/// automatically! So it needs to be freed manually (see cleanupMemory)!
EXPORT unsigned char *getFullMainDisplay();

/// Returns a screenshot of the full window
/// This is DPI Aware (see CMakeLists.txt)!
/// IMPORTANT: the memory management (cleanup of the returned data) must be done on the outside!!!
/// An Image can be created from the data with "cv::Mat(height, width, CV_8UC4, data);" but will not cleanup
/// automatically! So it needs to be freed manually (see cleanupMemory)!
/// For this function, the window must be opened, otherwise this will just return 0 (nullptr)
EXPORT unsigned char *getFullWindow(int windowID);

/// Part of the window start pos with size (from top left corner).
/// To translate this into a specific window, the getWindowBounds are needed
/// This is DPI Aware (see CMakeLists.txt)!
/// IMPORTANT: the memory management (cleanup of the returned data) must be done on the outside!!!
/// An Image can be created from the data with "cv::Mat(height, width, CV_8UC4, data);" but will not cleanup
/// automatically! So it needs to be freed manually!
/// For this function, the window must be opened, otherwise this will just return 0 (nullptr)
EXPORT unsigned char *getImageOfWindow(int windowID, int x, int y, int width, int height);

/// RGB values of pixel on display in hex format: 0x00bbggrr
/// R: val & 0xff
/// G: (val >> 8) & 0xff
/// B: (val >> 16) & 0xff
/// For this function, the window must be opened, otherwise this will just return 0
EXPORT unsigned long getPixelOfWindow(int windowID, int x, int y);

/// Returns the raw screen mouse position
EXPORT POINT getDisplayMousePos();

/// Returns the mouse position relative to the top left corner (0, 0) of the window.
/// If the window is not open, this will return (999999999, 999999999)
EXPORT POINT getWindowMousePos(int windowID);

/// Sets the raw screen mouse position
EXPORT void setDisplayMousePos(int x, int y);

/// Sets the mouse position relative to the top left corner (0, 0) of the window
/// If the window is not open, this will return false
EXPORT bool setWindowMousePos(int windowID, int x, int y);


// todo: get key state, set key, etc






/// Should always be the last function in the header and it has to return 5464696 in addition to input
/// Guard function for the init call so that the dart code can check if this lib was not modified
EXPORT int botGuard(int input);

#endif //NATIVE_WINDOW_H