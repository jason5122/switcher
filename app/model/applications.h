#import "model/application.h"
#import "model/window_element.h"
#import <Cocoa/Cocoa.h>
#import <unordered_map>

class applications {
public:
    std::unordered_map<CGWindowID, window_element> window_map;
    std::unordered_map<CFHashCode, CGWindowID> window_ref_map;

    applications();
    void add_window_ref(AXUIElementRef windowRef);
    void remove_window_ref(AXUIElementRef windowRef);

private:
    void add_app(NSRunningApplication* runningApp);
    void add_observer(application& app);
};
