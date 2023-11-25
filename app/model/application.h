#import "window.h"
#import <Cocoa/Cocoa.h>
#import <vector>

class application {
public:
    application(NSRunningApplication* runningApp);
    NSString* localizedName();
    bool is_xpc();
    void populate_initial_windows();
    void append_windows(std::vector<window>& windows);
    void add_observer();

private:
    NSRunningApplication* runningApp;
    ProcessSerialNumber psn;
    AXUIElementRef axUiElement;
    std::vector<window> windows;
};
