#import <Cocoa/Cocoa.h>

typedef enum {
    kCGCommandTab = 1,
    kCGCommandShiftTab = 2,
    kCGCommandKeyAboveTab = 6,
} CGSSymbolicHotKey;

extern "C" CGError CGSSetSymbolicHotKeyEnabled(CGSSymbolicHotKey hotKey, bool isEnabled);
