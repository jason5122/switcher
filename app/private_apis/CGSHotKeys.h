#import <Cocoa/Cocoa.h>

typedef enum {
    commandTab = 1,
    commandShiftTab = 2,
    commandKeyAboveTab = 6,
} CGSSymbolicHotKey;

extern CGError CGSSetSymbolicHotKeyEnabled(CGSSymbolicHotKey hotKey, bool isEnabled);
