#import "model/window_element.h"
#import <Cocoa/Cocoa.h>
#import <vector>

class application {
public:
    pid_t pid;
    AXUIElementRef axRef;

    application();
    application(pid_t pid);
    bool is_xpc();
    NSString* name();

private:
    ProcessSerialNumber psn;
    NSRunningApplication* runningApp;
};
