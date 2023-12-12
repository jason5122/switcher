#import "private_apis/CGS.h"
#import "util/log_util.h"
#import <Cocoa/Cocoa.h>
#import <vector>

inline std::vector<CGWindowID> CGWindowListIDs() {
    std::vector<CGWindowID> result;
    NSArray* windowList = (__bridge NSArray*)CGWindowListCopyWindowInfo(
        kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, kCGNullWindowID);
    for (NSDictionary* cgWindow in windowList) {
        CGWindowID wid = [cgWindow[(__bridge NSString*)kCGWindowNumber] intValue];
        int layer = [cgWindow[(__bridge NSString*)kCGWindowLayer] intValue];

        // CFStringRef title;
        // CGSCopyWindowProperty(CGSMainConnectionID(), wid, CFSTR("kCGSWindowTitle"), &title);
        // custom_log(OS_LOG_TYPE_DEFAULT, @"cgwindow", @"%@", title);

        if (layer == 0) {
            result.push_back(wid);
        }
    }
    return result;
}
