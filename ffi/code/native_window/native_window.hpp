#include <windows.h>
#include "../exports.h"

#ifndef NATIVE_WINDOW_H
#define NATIVE_WINDOW_H

/// Simple integer to detect dll library mismatches. Has to be incremented when native code is modified!
/// Also Modify the version in native_window.dart!
# define _NATIVE_CODE_VERSION 9

/// Simple integer to detect dll library mismatches. Has to be incremented when native code is modified!
/// Also Modify the version in native_window.dart!
EXPORT int nativeCodeVersion();

/// This must be called first to initialize the windowName (also resets the handle).
/// The windowID starts at 0 and has to be used for the other functions (only numbers 0 >= windowID < 100 )
/// Name Examples: "Path of Exile", "TL", "League of Legends"
EXPORT bool initWindow(int windowID, const char *windowName);

/// For Default windows it will be checked if the windowName is contained in the real name of the window
/// This can be disabled by setting "alwaysMatchEqual" to true
/// For Debugging the printCallback will be set (not null) to log from c++ code into dart code
EXPORT void initConfig(bool alwaysMatchEqual, void (*printCallback)(const char *, int));

/// initWindow must be called first
EXPORT bool isWindowOpen(int windowID);

/// initWindow must be called first
EXPORT bool hasWindowFocus(int windowID);

/// initWindow must be called first
EXPORT bool setWindowFocus(int windowID);

/// initWindow must be called first
/// The top left corner of the window is top, left (for borderless / fullscreen they are both 0)
/// width = right - left,  height = bottom - top
/// For inner size, use getWindowSize instead
EXPORT RECT getWindowBounds(int windowID);

/// initWindow must be called first
/// does not include top bar for windowed windows
/// For outer bounds in screen space, use getWindowBounds instead
EXPORT POINT getWindowSize(int windowID);

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

/// This will need display/screen coordinates that match the area of a window (or area inside it) !
/// This is DPI Aware (see CMakeLists.txt)!
/// IMPORTANT: the memory management (cleanup of the returned data) must be done on the outside!!!
/// An Image can be created from the data with "cv::Mat(height, width, CV_8UC4, data);" but will not cleanup
/// automatically! So it needs to be freed manually!
EXPORT unsigned char *getImageOfWindow(int windowID, int x, int y, int width, int height);

/// RGB values of pixel on display in hex format: 0x00bbggrr
/// R: val & 0xff
/// G: (val >> 8) & 0xff
/// B: (val >> 16) & 0xff
EXPORT unsigned long getPixelOfWindow(int x, int y);

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

/// Relative Mouse Move (can be negative)
EXPORT void moveMouse(int dx, int dy);

/// Scrolls by this amount of scroll wheel clicks into one direction (can be negative for reverse)
EXPORT void scrollMouse(int scrollClickAmount);
/// Sends a mouse event of: _MOUSEEVENTF_LEFTDOWN, _MOUSEEVENTF_LEFTUP, _MOUSEEVENTF_RIGHTDOWN, _MOUSEEVENTF_RIGHTUP,
/// _MOUSEEVENTF_MIDDLEDOWN, _MOUSEEVENTF_MIDDLEUP
EXPORT void sendMouseEvent(int mouseEvent);
/// keyUp=true will send a key release event and otherwise a key pressed down event is send
/// keyCode represents the virtual keycode of the key
EXPORT void sendKeyEvent(bool keyUp, unsigned short keyCode);
/// Same as sendKeyEvent, but with multiple key events at the same time
EXPORT void sendKeyEvents(bool keyUp, unsigned short* keyCodes, unsigned short amountOfKeys);

/// Returns if the key, or mouse button is currently down (also works correctly if left and right mouse buttons are
/// swapped). needs virtual key codes!
EXPORT bool isKeyDown(unsigned short keyCode);

/// Returns true if a key like caps lock, etc is toggled on. (also uses virtual key codes)
EXPORT bool isKeyToggled(unsigned short keyCode);

#endif //NATIVE_WINDOW_H