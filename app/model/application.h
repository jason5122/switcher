#import "model/window_element.h"
#import <Cocoa/Cocoa.h>
#import <vector>

class application {
public:
    std::vector<window_element> windows;

    application(NSRunningApplication* runningApp);
    NSString* name();
    bool is_xpc();
    void populate_initial_windows();
    void add_observer();
    static std::vector<application> get_running_applications();

private:
    NSRunningApplication* runningApp;
    ProcessSerialNumber psn;
    AXUIElementRef axUiElement;
};
