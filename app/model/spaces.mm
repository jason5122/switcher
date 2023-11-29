#import "private_apis/CGSSpace.h"
#import "private_apis/CGSWindows.h"
#import "spaces.h"

std::vector<CGWindowID> get_all_window_ids() {
    std::vector<CGWindowID> result;
    CFArrayRef screenDicts = CGSCopyManagedDisplaySpaces(_CGSDefaultConnection());
    for (NSDictionary* screen in (__bridge NSArray*)screenDicts) {
        for (NSDictionary* sp in screen[@"Spaces"]) {
            CGSSpaceID spaceId = [sp[@"id64"] intValue];
            // custom_log(OS_LOG_TYPE_DEFAULT, @"window-controller", @"%d", spaceId);

            int setTags = 0;
            int clearTags = 0;
            NSArray* windowIds = (__bridge NSArray*)CGSCopyWindowsWithOptionsAndTags(
                _CGSDefaultConnection(), 0, (__bridge CFArrayRef) @[ @(spaceId) ], 2, &setTags,
                &clearTags);
            // custom_log(OS_LOG_TYPE_DEFAULT, @"window-controller", @"%@", windowIds);

            for (int i = 0; i < windowIds.count; i++) {
                // https://stackoverflow.com/a/74696817/14698275
                id cfNumber = [windowIds objectAtIndex:i];
                CGWindowID wid = [((NSNumber*)cfNumber) intValue];
                // custom_log(OS_LOG_TYPE_DEFAULT, @"window-controller", @"%d", wid);

                CGWindowLevel level;
                CGSGetWindowLevel(_CGSDefaultConnection(), wid, &level);
                if (level == CGWindowLevelForKey(kCGNormalWindowLevelKey)) {
                    result.push_back(wid);
                }
            }
        }
    }
    return result;
}
