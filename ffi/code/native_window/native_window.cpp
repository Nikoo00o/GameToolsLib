#include "native_window.hpp"
#include <string>
#include <stdbool.h>
#include <stdio.h>

struct _WindowHelper
{
    HWND handle = 0;
    const char *name = 0;
};

/// Caches the handles and names for all used windows (set in init, handles may be reset in _getWindowHandle)
_WindowHelper _windows[1000]{};

/// Used for debugging / logging into dart code and is initialized in
void (*_printToDart)(const char *, int);

bool _alwaysMatchEqual = false;
/// Caches the main display (reset in _getWindowHandle)
HDC _mainDisplay = 0;

/// If the source can be split by "- ", then it will only compare the last part to the target name and return true.
/// otherwise false.
inline bool _isLastPartEqualTo(const char *source, const char *targetName)
{
    size_t srcLength = strlen(source);
    size_t targetLength = strlen(targetName);
    size_t startPos = 0;
    for ( size_t i = 0; i < srcLength - 1; ++i )
    {
        if ( (source[i] == '-' || source[i] == -106)  && source[i + 1] == ' ' )
        {
            startPos = i + 2; // start at the character after the 2 delimiters
        }
    }
    // now if startPos was set and the remaining of source is same length as target, just default string compare them
    if ( startPos > 0 && srcLength - startPos == targetLength )
    {
        for ( size_t i = 0; i < targetLength; ++i )
        {
            if ( targetName[i] != source[i + startPos] )
            {
                return false;
            }
        }
        return true;
    }
    return false;
}

/// Returns true if only the source, but not the target contains a " - " delimiter which is used for browser, etc
inline bool _onlyCompareLastPart(const char *source, const char *targetName)
{
    size_t srcLength = strlen(source);
    size_t targetLength = strlen(targetName);
    for ( size_t i = 1; i < targetLength - 1; ++i )
    {
        if (targetName[i - 1] == ' ' && (targetName[i] == '-' || targetName[i] == -106) && targetName[i + 1] == ' ' )
        {
            return false;
        }
    }
    for ( size_t i = 1; i < srcLength - 1; ++i )
    {
        if (source[i - 1] == ' ' && (source[i] == '-' || source[i] == -106) && source[i + 1] == ' ' )
        {
            return true;
        }
    }
    return false;
}

/// Helper method that will be called with every open window handle
int __stdcall _enumWindows(HWND hwnd, LPARAM lParam)
{
    _WindowHelper *helper = (_WindowHelper *) lParam;
    int length = GetWindowTextLengthA(hwnd);
    if ( length > 2 )
    {
        char *windowTitle = new char[length + 1];
        bool isEqual = false;
        int written = GetWindowTextA(hwnd, windowTitle, length + 1);
        if ( written > 1 && IsWindowVisible(hwnd))
        {
            if ( _printToDart != 0 )
            {
                _printToDart(windowTitle, 1); // 1 is used for window names
            }
            if ( windowTitle[1] == ':' && windowTitle[2] == '\\' )
            {
                // special case: windows explorer.exe (must be equal here)
                isEqual = strcmp(windowTitle, helper->name) == 0;
            } else if ( _onlyCompareLastPart(windowTitle, helper->name) )
            {
                // todo: better use wchar to be able to compare correctly!
                // special case: discord, or browser like firefox, etc (must be equal to last part here)
                isEqual = _isLastPartEqualTo(windowTitle, helper->name);
            } else
            {
                if ( _alwaysMatchEqual )
                {
                    // depending on bool, exact matching here!
                    isEqual = strcmp(windowTitle, helper->name) == 0;
                } else
                {
                    // default named windows: windowName only must be contained in windowTitle
                    isEqual = strstr(windowTitle, helper->name) != 0;
                }
            }
        }
        delete[] windowTitle;
        if ( isEqual )
        {
            helper->handle = hwnd;
            return 0;
        }
    }
    return 1;
}

/// initWindow must be called first. Returns the handle related to the windowID and otherwise nullptr if the window is not open
inline HWND _getWindowHandle(int windowID)
{
    if ( windowID < 0 || windowID > 999 )
    {
        return 0;
    }
    _WindowHelper *helper = &_windows[windowID];
    if ( helper->handle != 0 )
    {
        if ( IsWindow(helper->handle))
        {
            return helper->handle;
        } else
        {
            helper->handle = 0;
            if ( _mainDisplay != 0 )
            {
                ReleaseDC(0, _mainDisplay);
                _mainDisplay = GetDC(0);
            }
        }
    }
    if ( helper->name == 0 )
    {
        return 0;
    }
    EnumWindows(_enumWindows, (LPARAM) helper);
    if ( _printToDart != 0 )
    {
        if ( helper->handle != 0 )
        {
            DWORD affinity;
            GetWindowDisplayAffinity(helper->handle, &affinity);
            char str[20];
            sprintf_s(str, "%d", (int) affinity);
            _printToDart(str, 2); // 2 is used for end of window names with window affinity
        } else
        {
            const char *noHandle = "No handle";
            _printToDart(noHandle, 2); // 2 is used for end of window names with window affinity
        }
    }
    return helper->handle;
}

/// Sets and returns the cached main display (only reset when handle is lost in _getWindowHandle)
inline HDC _getMainDisplay()
{
    if ( _mainDisplay == 0 )
    {
        _mainDisplay = GetDC(0);
    }
    return _mainDisplay;
}

#define _SRCCOPY 0x00CC0020ul
#define _BI_RGB 0L
#define _DIB_RGB_COLORS 0

/// Returns an image of the main display from the top left corner
inline unsigned char *_getImage(int x, int y, int width, int height)
{
    HDC deviceContext = _getMainDisplay();
    HDC memoryDeviceContext = CreateCompatibleDC(deviceContext);
    HBITMAP bitmap = CreateCompatibleBitmap(deviceContext, width, height);
    HGDIOBJ oldObject = SelectObject(memoryDeviceContext, bitmap);
    BitBlt(memoryDeviceContext, 0, 0, width, height, deviceContext, x, y, _SRCCOPY); // now image data is in bitmap

    BITMAPINFOHEADER bi; // format on how the bitmap is interpreted for opencv
    bi.biSize = sizeof(BITMAPINFOHEADER);
    bi.biWidth = width;
    bi.biHeight = -height;
    bi.biPlanes = 1;
    bi.biBitCount = 32; // RGBA
    bi.biCompression = _BI_RGB; // no compression
    bi.biSizeImage = 0; // because no compression
    bi.biXPelsPerMeter = 1; // irrelevant
    bi.biYPelsPerMeter = 1; // irrelevant
    bi.biClrUsed = 3; // irrelevant
    bi.biClrImportant = 4; // irrelevant

    unsigned char *array = (unsigned char *) malloc(
            height * width * 4 * sizeof(unsigned char));// RGBA: 8 uint with 4 channels, and dimensions
    GetDIBits(memoryDeviceContext, bitmap, 0, height, array, (BITMAPINFO * ) & bi, _DIB_RGB_COLORS);
    // copy into buffer: 0 start, height = lines, mat.data is buffer, bitmapinfo, rgba info

    SelectObject(memoryDeviceContext, oldObject);
    DeleteObject(bitmap);
    DeleteDC(memoryDeviceContext); // delete dc
    return array;
}

// todo: not working for directx / opengl windows
inline unsigned char *_getFullWindowImageOld(int windowID)
{
    HWND handle = _getWindowHandle(windowID);
    if ( handle == 0 )
    {
        return 0;
    }
    RECT bounds = getWindowBounds(windowID);
    HDC winDc = GetDC(handle);
    int width = bounds.right - bounds.left;
    int height = bounds.bottom - bounds.top;

    BITMAPINFOHEADER bi; // format on how the bitmap is interpreted for opencv
    bi.biSize = sizeof(BITMAPINFOHEADER);
    bi.biWidth = width;
    bi.biHeight = -height;
    bi.biPlanes = 1;
    bi.biBitCount = 32; // RGBA
    bi.biCompression = _BI_RGB; // no compression
    bi.biSizeImage = 0; // because no compression
    bi.biXPelsPerMeter = 1; // irrelevant
    bi.biYPelsPerMeter = 1; // irrelevant
    bi.biClrUsed = 3; // irrelevant
    bi.biClrImportant = 4; // irrelevant

    HDC memoryDC = CreateCompatibleDC(winDc);
    HBITMAP bitmap = CreateCompatibleBitmap(winDc, width, height);
    HGDIOBJ oldObject = SelectObject(memoryDC, bitmap);

    // RGBA: 8 uint with 4 channels, and dimensions
    unsigned char *array = (unsigned char *) malloc(height * width * 4 * sizeof(unsigned char));
    BitBlt(memoryDC, 0, 0, width, height, winDc, 0, 0, _SRCCOPY | CAPTUREBLT);
    GetDIBits(memoryDC, bitmap, 0, height, array,(BITMAPINFO * ) & bi, _DIB_RGB_COLORS);

    SelectObject(memoryDC, oldObject);
    DeleteObject(bitmap);
    DeleteDC(memoryDC);
    ReleaseDC(handle, winDc);
    return array;
}

EXPORT int nativeCodeVersion()
{
    return _NATIVE_CODE_VERSION;
}

EXPORT bool initWindow(int windowID, const char *windowName)
{
    if ( windowID < 0 || windowID > 99 )
    {
        return false;
    }
    _windows[windowID].name = windowName;
    _windows[windowID].handle = 0;
    return true;
}

EXPORT void initConfig(bool alwaysMatchEqual, void (*printCallback)(const char *, int))
{
    _printToDart = printCallback;
    _alwaysMatchEqual = alwaysMatchEqual;
}

EXPORT bool isWindowOpen(int windowID)
{
    return _getWindowHandle(windowID) != 0;
}

EXPORT bool hasWindowFocus(int windowID)
{
    HWND handle = _getWindowHandle(windowID);
    if ( handle != 0 )
    {
        HWND focusWindow = GetForegroundWindow();
        return handle == focusWindow;
    }
    return false;
}

EXPORT bool setWindowFocus(int windowID)
{
    HWND handle = _getWindowHandle(windowID);
    if ( handle != 0 )
    {
        return SetForegroundWindow(handle);
    }
    return false;
}

#define _INVALID_VALUE 999999999
#define _INVALID_VALUE_UL 999999999ul

EXPORT RECT getWindowBounds(int windowID)
{
    HWND handle = _getWindowHandle(windowID);
    if ( handle != 0 )
    {
        RECT bounds;
        GetWindowRect(handle, &bounds);
        return bounds;
    }
    return RECT{_INVALID_VALUE, _INVALID_VALUE, _INVALID_VALUE, _INVALID_VALUE};
}

#define _HOZRES 8

EXPORT unsigned int getMainDisplayWidth()
{
    return GetDeviceCaps(_getMainDisplay(), _HOZRES);
}

#define _VERTREX 10

EXPORT unsigned int getMainDisplayHeight()
{
    return GetDeviceCaps(_getMainDisplay(), _VERTREX);
}

#define _WM_CLOSE 0x0010

EXPORT bool closeWindow(int windowID)
{
    HWND handle = _getWindowHandle(windowID);
    if ( handle != 0 )
    {
        SendMessageA(handle, _WM_CLOSE, 0, 0);
        return true;
    }
    return false;
}

EXPORT void cleanupMemory(unsigned char *data)
{
    free(data);
}

EXPORT unsigned char *getFullMainDisplay()
{
    unsigned int width = getMainDisplayWidth();
    unsigned int height = getMainDisplayHeight();
    return _getImage(0, 0, width, height);
}

EXPORT unsigned char *getFullWindow(int windowID)
{
    HWND handle = _getWindowHandle(windowID);
    if ( handle == 0 )
    {
        return 0;
    }
    RECT bounds = getWindowBounds(windowID);
    POINT pos{bounds.left, bounds.top};
    POINT size{bounds.right - bounds.left, bounds.bottom - bounds.top};
    return _getImage(pos.x, pos.y, size.x, size.y);
}

EXPORT unsigned char *getImageOfWindow(int windowID, int x, int y, int width, int height)
{
    HWND handle = _getWindowHandle(windowID);
    if ( handle == 0 )
    {
        return 0;
    }
    POINT pos{x, y};
    POINT size{width, height};
    ClientToScreen(handle, &pos);
    return _getImage(pos.x, pos.y, size.x, size.y);
}

EXPORT unsigned long getPixelOfWindow(int windowID, int x, int y)
{
    HWND handle = _getWindowHandle(windowID);
    if ( handle == 0 )
    {
        return _INVALID_VALUE_UL;
    }
    POINT point{x, y};
    ClientToScreen(handle, &point);
    HDC hdc = _getMainDisplay();
    COLORREF colorRef = GetPixel(hdc, point.x, point.y);
    return (unsigned long) colorRef;
}

EXPORT POINT getDisplayMousePos()
{
    POINT point;
    GetCursorPos(&point);
    return point;
}

EXPORT POINT getWindowMousePos(int windowID)
{
    HWND handle = _getWindowHandle(windowID);
    if ( handle == 0 )
    {
        return POINT{_INVALID_VALUE, _INVALID_VALUE};
    }
    POINT point = getDisplayMousePos();
    ScreenToClient(handle, &point);
    return point;
}

EXPORT void setDisplayMousePos(int x, int y)
{
    SetCursorPos(x, y);
}

EXPORT bool setWindowMousePos(int windowID, int x, int y)
{
    HWND handle = _getWindowHandle(windowID);
    if ( handle == 0 )
    {
        return false;
    }
    POINT point{x, y};
    ClientToScreen(handle, &point);
    setDisplayMousePos(point.x, point.y);
    return true;
}

#define _INPUT_MOUSE 0
#define _MOUSEEVENTF_MOVE 0x0001

EXPORT void moveMouse(int dx, int dy)
{
    INPUT input;
    input.type = _INPUT_MOUSE;
    input.mi.mouseData = 0;
    input.mi.time = 0;
    input.mi.dx = dx;
    input.mi.dy = dy;
    input.mi.dwFlags = _MOUSEEVENTF_MOVE;
    SendInput(1, &input, sizeof(input));
}

#define _MOUSEEVENTF_WHEEL 0x0800

EXPORT void scrollMouse(int scrollClickAmount)
{
    INPUT input;
    input.type = _INPUT_MOUSE;
    input.mi.time = 0;
    input.mi.mouseData = scrollClickAmount * 120; // may be negative (120 is one click in any direction)
    input.mi.dwFlags = _MOUSEEVENTF_WHEEL;
    SendInput(1, &input, sizeof(input));
}

#define _MOUSEEVENTF_LEFTDOWN    0x0002
#define _MOUSEEVENTF_LEFTUP      0x0004
#define _MOUSEEVENTF_RIGHTDOWN   0x0008
#define _MOUSEEVENTF_RIGHTUP     0x0010
#define _MOUSEEVENTF_MIDDLEDOWN  0x0020
#define _MOUSEEVENTF_MIDDLEUP    0x0040

EXPORT void sendMouseEvent(int mouseEvent)
{
    INPUT input;
    input.type = _INPUT_MOUSE;
    input.mi.time = 0;
    input.mi.dwFlags = mouseEvent;
    SendInput(1, &input, sizeof(INPUT));
}

#define _INPUT_KEYBOARD 1
#define _KEYEVENTF_SCANCODE 0x0008
#define _KEYEVENTF_KEYUP 0x0002
#define _MAPVK_VK_TO_VSC 0

EXPORT void sendKeyEvent(bool keyUp, unsigned short keyCode)
{
    INPUT input;
    input.type = _INPUT_KEYBOARD;
    input.ki.time = 0;
    input.ki.wVk = 0;
    input.ki.dwExtraInfo = 0;
    if ( keyUp )
        input.ki.dwFlags = _KEYEVENTF_SCANCODE | _KEYEVENTF_KEYUP;
    else
        input.ki.dwFlags = _KEYEVENTF_SCANCODE;
    input.ki.wScan = (WORD) MapVirtualKeyA(keyCode, _MAPVK_VK_TO_VSC);
    SendInput(1, &input, sizeof(INPUT));
}

EXPORT void sendKeyEvents(bool keyUp, unsigned short *keyCodes, unsigned short amountOfKeys)
{
    INPUT *inputs = (INPUT *) malloc(amountOfKeys * sizeof(INPUT));
    for ( unsigned short i = 0; i < amountOfKeys; ++i )
    {
        INPUT &input = inputs[i];
        input.type = _INPUT_KEYBOARD;
        input.ki.time = 0;
        input.ki.wVk = 0;
        input.ki.dwExtraInfo = 0;
        if ( keyUp )
            input.ki.dwFlags = _KEYEVENTF_SCANCODE | _KEYEVENTF_KEYUP;
        else
            input.ki.dwFlags = _KEYEVENTF_SCANCODE;
        input.ki.wScan = (WORD) MapVirtualKeyA(keyCodes[i], _MAPVK_VK_TO_VSC);
    }
    SendInput(amountOfKeys, inputs, sizeof(INPUT));
    free(inputs);
}

#define _SM_SWAPBUTTON 23

EXPORT bool isKeyDown(unsigned short keyCode)
{
    if ( keyCode <= 0x02 && GetSystemMetrics(_SM_SWAPBUTTON))
    {
        return (GetAsyncKeyState(keyCode == 0x02 ? 0x01 : 0x02) & 0x8000); // left and right mouse button swapped
    }
    return GetAsyncKeyState(keyCode) & 0x8000;
}

EXPORT bool isKeyToggled(unsigned short keyCode)
{
    return GetKeyState(keyCode) & 0x01; // caps lock, num lock, etc
}