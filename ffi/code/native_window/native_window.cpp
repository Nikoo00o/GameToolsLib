#include "native_window.hpp"
#include <string>
#include <stdbool.h>

 /// internal guard function to detect library changes
 int _topGuard()
{
    return 143921;
}

/// internal guard value to detect library changes
int _someGuardVal = 401293;

struct _WindowHelper
{
    HWND handle = 0;
    const char* name = 0;
};

/// Caches the handles and names for all used windows (set in init, handles may be reset in _getWindowHandle)
_WindowHelper _windows[1000] {};
/// Debug Variable used to print all window names (set in init)
bool _printWindowNames = false;

bool _alwaysMatchEqual = false;
/// Caches the main display (reset in _getWindowHandle)
HDC _mainDisplay = 0;

/// If the source can be split by "- ", then it will only compare the last part to the targetname and return true.
/// otherwise false. always false if the target name contains "- "
bool _isLastPartEqualTo(const char* source, const char* targetName)
{
    size_t srcLength = strlen(source);
    size_t targetLength = strlen(targetName);
    // check if delimitters are in target (dont check last char, because 1 char ahead is checked)
    for (size_t i = 0; i < targetLength - 1; ++i)
    {
        if (targetName[i] == '-' && targetName[i + 1] == ' ')
        {
            return false;
        }
    }
    size_t startPos = 0;
    for (size_t i = 0; i < srcLength - 1; ++i)
    {
        if (source[i] == '-' && source[i + 1] == ' ')
        {
            startPos = i + 2; // start at the character after the 2 delimitters
        }
    }
    // now if startPos was set and the remaining of source is same length as target, just default string compare them
    if (startPos > 0 && srcLength - startPos == targetLength)
    {
        for (size_t i = 0; i < targetLength; ++i)
        {
            if (targetName[i] != source[i + startPos])
            {
                return false;
            }
        }
        return true;
    }
    return false;
}

/// Helper method that will be called with every open window handle
int __stdcall _enumWindows(HWND hwnd, LPARAM lParam)
{
    _WindowHelper* helper = (_WindowHelper*) lParam;
    int length = GetWindowTextLengthA(hwnd);
    if (length > 2)
    {
        char* windowTitle = new char[length + 1];
        bool isEqual = false;
        bool written = GetWindowTextA(hwnd, windowTitle, length + 1);
        if (written && IsWindowVisible(hwnd))
        {
            if (_printWindowNames)
            {
                printf("Window: %s\n", windowTitle);
            }
            if (windowTitle[1] == ':' && windowTitle[2] == '\\')
            {
                // special case: windows explorer.exe (must be equal here)
                isEqual = strcmp(windowTitle, helper->name) == 0;
            }
            else if (_isLastPartEqualTo(windowTitle, helper->name))
            {
                // special case: discord, or browser like firefox, etc (must be equal to last part here)
                isEqual = true;
            }
            else
            {
                if(_alwaysMatchEqual)
                {
                    // depending on bool, exact matching here!
                    isEqual = strcmp(windowTitle, helper->name) == 0;
                }
                else
                {
                    // default named windows: windowName only must be contained in windowTitle
                    isEqual = strstr(windowTitle, helper->name) != 0;
                }
            }
        }
        delete[] windowTitle;
        if (isEqual)
        {
            helper->handle = hwnd;
            return 0;
        }
    }
    return 1;
}

/// initWindow must be called first. Returns the handle related to the windowID and otherwise nullptr if the window is not open
HWND _getWindowHandle(int windowID)
{
    if (windowID < 0 || windowID > 999)
    {
        return 0;
    }
    _WindowHelper* helper = &_windows[windowID];
    if (helper->handle != 0)
    {
        if (IsWindow(helper->handle))
        {
            return helper->handle;
        }
        else
        {
            helper->handle = 0;
            if(_mainDisplay != 0)
            {
                ReleaseDC(0, _mainDisplay);
                _mainDisplay = GetDC(0);
            }
        }
    }
    if (helper->name == 0)
    {
        return 0;
    }
    EnumWindows(_enumWindows, (LPARAM) helper);
    return helper->handle;
}

/// Sets and returns the cached main display (only reset when handle is lost in _getWindowHandle)
HDC _getMainDisplay()
{
    if(_mainDisplay == 0)
    {
        _mainDisplay = GetDC(0);
    }
    return _mainDisplay;
}

/// Returns an image of the main display from the top left corner
unsigned char* _getImage(int x, int y, int width, int height)
{
    HDC deviceContext = _getMainDisplay();
    HDC memoryDeviceContext = CreateCompatibleDC(deviceContext);
    HBITMAP bitmap = CreateCompatibleBitmap(deviceContext, width, height);
    SelectObject(memoryDeviceContext, bitmap);
    const DWORD _SRCCOPY = (DWORD)0x00CC0020;
    BitBlt(memoryDeviceContext, 0, 0, width, height, deviceContext, x, y, _SRCCOPY); // now image data is in bitmap

    BITMAPINFOHEADER bi; // format on how the bitmap is interpreted for opencv
    bi.biSize = sizeof(BITMAPINFOHEADER);
    bi.biWidth = width;
    bi.biHeight = -height;
    bi.biPlanes = 1;
    bi.biBitCount = 32; // RGBA
    bi.biCompression = BI_RGB; // no compression
    bi.biSizeImage = 0; // because no compression
    bi.biXPelsPerMeter = 1; // irrelevant
    bi.biYPelsPerMeter = 1; // irrelevant
    bi.biClrUsed = 3; // irrelevant
    bi.biClrImportant = 4; // irrelevant

    unsigned char* array = (unsigned char* ) malloc(height * width * 4 * sizeof(unsigned char));// RGBA: 8 uint with 4 channels, and dimensions
    const int _DIB_RGB_COLORS = 0;
    GetDIBits(memoryDeviceContext, bitmap, 0, height, array, (BITMAPINFO*) &bi, _DIB_RGB_COLORS);
    // copy into buffer: 0 start, height = lines, mat.data is buffer, bitmapinfo, rgba info

    DeleteObject(bitmap);
    DeleteDC(memoryDeviceContext); // delete dc
    return array;
}

EXPORT bool initWindow(int windowID, const char* windowName, bool alwaysMatchEqual, bool printWindowNames)
{
    if (windowID < 0 || windowID > 99)
    {
        return false;
    }
    _windows[windowID].name = windowName;
    _windows[windowID].handle = 0;
    _printWindowNames = printWindowNames;
    _alwaysMatchEqual = alwaysMatchEqual;
    return true;
}

EXPORT bool isWindowOpen(int windowID)
{
    return _getWindowHandle(windowID) != 0;
}

EXPORT bool hasWindowFocus(int windowID)
{
    HWND handle = _getWindowHandle(windowID);
    if (handle != 0)
    {
        HWND focusWindow = GetForegroundWindow();
        return handle == focusWindow;
    }
    return false;
}

EXPORT bool setWindowFocus(int windowID)
{
    HWND handle = _getWindowHandle(windowID);
    if (handle != 0)
    {
        SetForegroundWindow(handle);
        return true;
    }
    return false;
}

EXPORT RECT getWindowBounds(int windowID)
{
    HWND handle = _getWindowHandle(windowID);
    if (handle != 0)
    {
        RECT bounds;
        GetWindowRect(handle, &bounds);
        return bounds;
    }
    return RECT {999999999, 999999999, 999999999, 999999999};
}

EXPORT unsigned int getMainDisplayWidth()
{
    const int _HOZRES = 8;
    return GetDeviceCaps(_getMainDisplay(), _HOZRES);
}

EXPORT unsigned int getMainDisplayHeight()
{
    const int _VERTREX = 10;
    return GetDeviceCaps(_getMainDisplay(), _VERTREX);
}

EXPORT bool closeWindow(int windowID)
{
    HWND handle = _getWindowHandle(windowID);
    if (handle != 0)
    {
        const int _WM_CLOSE = 0x0010;
        SendMessageA(handle, _WM_CLOSE, 0, 0);
        return true;
    }
    return false;
}

EXPORT void cleanupMemory(unsigned char* data)
{
    free(data);
}

EXPORT unsigned char* getFullMainDisplay()
{
    unsigned int width = getMainDisplayWidth();
    unsigned int height = getMainDisplayHeight();
    return _getImage(0, 0, width, height);
}

EXPORT unsigned char* getFullWindow(int windowID)
{
    HWND handle = _getWindowHandle(windowID);
    if(handle == 0)
    {
        return 0;
    }
    RECT bounds = getWindowBounds(windowID);
    POINT pos { bounds.left, bounds.top };
    POINT size { bounds.right - bounds.left, bounds.bottom - bounds.top };
    ClientToScreen(handle, &pos);
    ClientToScreen(handle, &size);
    return _getImage(pos.x, pos.y, size.x, size.y);
}

EXPORT unsigned char* getImageOfWindow(int windowID, int x, int y, int width, int height)
{
    HWND handle = _getWindowHandle(windowID);
    if(handle == 0)
    {
        return 0;
    }
    POINT pos { x, y };
    POINT size { width,height };
    ClientToScreen(handle, &pos);
    ClientToScreen(handle, &size);
    return _getImage(pos.x, pos.y, size.x, size.y);
}

EXPORT unsigned long getPixelOfWindow(int windowID, int x, int y)
{
    HWND handle = _getWindowHandle(windowID);
    if(handle == 0)
    {
        return 999999999ul;
    }
    POINT point { x, y };
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
    if(handle == 0)
    {
        return POINT {999999999, 999999999};
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
    if(handle == 0)
    {
        return false;
    }
    POINT point { x, y };
    ClientToScreen(handle, &point);
    setDisplayMousePos(point.x, point.y);
    return true;
}

EXPORT int botGuard(int input)
{
    return _topGuard() + 4919482 + input + _someGuardVal; // returns 5464696
}