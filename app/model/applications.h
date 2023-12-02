#import "model/application.h"
#import "model/window_element.h"
#import <Cocoa/Cocoa.h>
#import <unordered_map>

class applications {
public:
    std::unordered_map<CGWindowID, window_element> window_map;
    std::unordered_map<CGWindowID, AXUIElementRef> ref_map;
    std::unordered_map<CFHashCode, CGWindowID> window_ref_map;
    std::vector<AXUIElementRef> aaa;
    AXUIElementRef ay;

    applications();
    void SHIT(AXUIElementRef inRef);

private:
    void add_observer(application& app);
};
