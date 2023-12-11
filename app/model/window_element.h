#import <Cocoa/Cocoa.h>

class window_element {
public:
    CGWindowID wid;
    AXUIElementRef windowRef;
    ProcessSerialNumber psn;

    window_element();
    window_element(AXUIElementRef windowRef);
    void focus();
};
