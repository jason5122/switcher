#import "private_apis/Accessiblity.h"
#import <Cocoa/Cocoa.h>

class window {
public:
    CGWindowID wid;

    window(pid_t app_pid, AXUIElementRef windowRef);
    void focus();

private:
    pid_t app_pid;
    AXUIElementRef windowRef;
    ProcessSerialNumber psn;
};
