#import <Cocoa/Cocoa.h>

class application {
public:
    application(NSRunningApplication* runningApp);
    NSString* localizedName();
    bool is_xpc();
    void add_observer();

    // private:
    NSRunningApplication* runningApp;
    ProcessSerialNumber psn;
    AXUIElementRef axUiElement;
};
