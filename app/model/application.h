#import "model/window_element.h"
#import <Cocoa/Cocoa.h>
#import <vector>

class application {
public:
    pid_t pid;
    ProcessSerialNumber psn;
    std::vector<window_element> windows;
    AXUIElementRef axUiElement;
    NSRunningApplication* runningApp;

    application(NSRunningApplication* runningApp);
    NSString* name();
    bool is_xpc();
    void populate_initial_windows();
};
