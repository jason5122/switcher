#import <Cocoa/Cocoa.h>

typedef size_t CGSSpaceID;
typedef int CGSConnectionID;

extern "C" CGSConnectionID _CGSDefaultConnection();
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

typedef uint64_t CGSManagedDisplay;

extern "C" CGSManagedDisplay kCGSPackagesMainDisplayIdentifier;

extern "C" CFArrayRef CGSCopyWindowsWithOptionsAndTags(CGSConnectionID cid, int owner,
                                                       CFArrayRef spaces, int options,
                                                       int* setTags, int* clearTags);
extern "C" CFArrayRef CGSCopyManagedDisplaySpaces(CGSConnectionID cid);
extern "C" CGSSpaceID CGSManagedDisplayGetCurrentSpace(CGSConnectionID cid,
                                                       CGSManagedDisplay display);
extern "C" CGWindowLevel CGSGetWindowLevel(CGSConnectionID cid, CGWindowID wid,
                                           CGWindowLevel* level);

extern "C" CGError CGSCopyWindowProperty(CGSConnectionID cid, CGWindowID wid, CFStringRef key,
                                         CFStringRef* output);
