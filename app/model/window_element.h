#import "private_apis/Accessiblity.h"
#import <Cocoa/Cocoa.h>

class window_element {
public:
    CGWindowID wid;
    NSString* title;
    NSImage* icon;

    window_element();
    window_element(pid_t app_pid, AXUIElementRef windowRef, NSImage* icon);
    void focus();

private:
    pid_t app_pid;
    AXUIElementRef windowRef;
    ProcessSerialNumber psn;
};
