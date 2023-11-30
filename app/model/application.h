#import "model/window_element.h"
#import <Cocoa/Cocoa.h>
#import <vector>

class application {
public:
    application(NSRunningApplication* runningApp);
    NSString* localizedName();
    bool is_xpc();
    void populate_initial_windows();
    void append_windows(std::vector<window_element>& windows);
    void add_observer();
    static std::vector<application> get_running_applications();

private:
    NSRunningApplication* runningApp;
    ProcessSerialNumber psn;
    AXUIElementRef axUiElement;
    std::vector<window_element> windows;
};
