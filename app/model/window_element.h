#import "private_apis/AXUI.h"
#import <Cocoa/Cocoa.h>

class window_element {
public:
    CGWindowID wid;
    NSString* title;
    NSImage* icon;

    window_element();
    window_element(pid_t app_pid, AXUIElementRef windowRef, NSImage* icon);
    window_element(AXUIElementRef windowRef);
    void focus();

// private:
    AXUIElementRef windowRef;
    ProcessSerialNumber psn;
};
