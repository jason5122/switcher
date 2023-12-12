#import <Cocoa/Cocoa.h>
#import <vector>

inline std::vector<CGWindowID> CGWindowListIDs() {
    std::vector<CGWindowID> result;
    NSArray* windowList = (__bridge NSArray*)CGWindowListCopyWindowInfo(
        kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, kCGNullWindowID);
    for (NSDictionary* cgWindow in windowList) {
        int layer = [cgWindow[(__bridge NSString*)kCGWindowLayer] intValue];
        if (layer == 0) {
            CGWindowID wid = [cgWindow[(__bridge NSString*)kCGWindowNumber] intValue];
            result.push_back(wid);
        }
    }
    return result;
}
