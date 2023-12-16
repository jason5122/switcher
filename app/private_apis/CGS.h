#import <Cocoa/Cocoa.h>

typedef size_t CGSSpaceID;
typedef int CGSConnectionID;

extern "C" CGSConnectionID CGSMainConnectionID();
extern "C" CGSSpaceID CGSSpaceCreate(CGSConnectionID cid, int unknown, CFDictionaryRef options);
extern "C" void CGSSpaceDestroy(CGSConnectionID cid, CGSSpaceID sid);
extern "C" void CGSSpaceSetAbsoluteLevel(CGSConnectionID cid, CGSSpaceID space, int level);
extern "C" void CGSAddWindowsToSpaces(CGSConnectionID cid, CFArrayRef windows, CFArrayRef spaces);
extern "C" void CGSShowSpaces(CGSConnectionID cid, CFArrayRef spaces);
extern "C" void CGSHideSpaces(CGSConnectionID cid, CFArrayRef spaces);

typedef enum {
    kCGCommandTab = 1,
    kCGCommandShiftTab = 2,
    kCGCommandKeyAboveTab = 6,
} CGSSymbolicHotKey;

extern "C" CGError CGSSetSymbolicHotKeyEnabled(CGSSymbolicHotKey hotKey, bool isEnabled);

extern "C" CGError CGSCopyWindowProperty(CGSConnectionID cid, CGWindowID wid, CFStringRef key,
                                         CFStringRef* output);

extern "C" CGError CGSGetWindowOwner(CGSConnectionID cid, CGWindowID wid,
                                     CGSConnectionID* outOwner);
extern "C" CGError CGSGetConnectionPSN(CGSConnectionID cid, ProcessSerialNumber* psn);

enum {
    kCGSWindowCaptureNominalResolution = 0x0200,
    kCGSCaptureIgnoreGlobalClipShape = 0x0800,
};
typedef uint32_t CGSWindowCaptureOptions;

extern "C" CFArrayRef CGSHWCaptureWindowList(CGSConnectionID cid, CGWindowID* wid,
                                             uint32_t windowCount, uint32_t options);
