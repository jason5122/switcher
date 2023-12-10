#import "model/window_element.h"
#import <Cocoa/Cocoa.h>
#import <vector>

class application {
public:
    pid_t pid;
    ProcessSerialNumber psn;
    std::vector<window_element> windows;
    AXUIElementRef axUiElement;

    application(pid_t pid);
    bool is_xpc();
    void populate_initial_windows();
};
