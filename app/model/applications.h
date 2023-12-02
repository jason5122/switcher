#import "model/application.h"
#import "model/window_element.h"
#import <Cocoa/Cocoa.h>
#import <unordered_map>
#import <unordered_set>

class applications {
public:
    std::unordered_map<CGWindowID, window_element> window_map;
    // std::unordered_map<AXUIElementRef, window_element> window_ref_map;
    // std::vector<AXUIElementRef> window_refs;
    std::unordered_set<CFHashCode> window_refs;

    applications();

private:
    void add_observer(application& app);
};
