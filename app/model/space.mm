#import "space.h"
#import "util/log_util.h"

space::space(int level) {
    int flag = 0x1;
    spaceId = CGSSpaceCreate(CGSMainConnectionID(), flag, nil);
    CGSSpaceSetAbsoluteLevel(CGSMainConnectionID(), spaceId, level);
    CGSShowSpaces(CGSMainConnectionID(), (__bridge CFArrayRef) @[ @(spaceId) ]);
}

void space::add_window(NSWindow* window) {
    CGSAddWindowsToSpaces(CGSMainConnectionID(), (__bridge CFArrayRef) @[ @(window.windowNumber) ],
                          (__bridge CFArrayRef) @[ @(spaceId) ]);
}

std::vector<CGWindowID>
space::get_all_valid_window_ids(std::unordered_map<CGWindowID, window_element>& window_map) {
    std::vector<CGWindowID> result;
    NSArray* windowList = (__bridge NSArray*)CGWindowListCopyWindowInfo(
        kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, kCGNullWindowID);

    for (NSDictionary* cgWindow in windowList) {
        int layer = [cgWindow[(__bridge NSString*)kCGWindowLayer] intValue];
        if (layer == 0) {
            CGWindowID wid = [cgWindow[(__bridge NSString*)kCGWindowNumber] intValue];

            CFStringRef title;
            CGSCopyWindowProperty(CGSMainConnectionID(), wid, CFSTR("kCGSWindowTitle"), &title);
            // custom_log(OS_LOG_TYPE_DEFAULT, @"space", (__bridge NSString*)title);

            result.push_back(wid);

            // if (window_map.count(wid)) {
            // pid_t pid;
            // AXUIElementGetPid(window_map[wid].windowRef, &pid);
            // // if (onlyActiveApp && pid != frontmost_pid) continue;

            // CFStringRef subroleRef;
            // AXUIElementCopyAttributeValue(window_map[wid].windowRef, kAXSubroleAttribute,
            //                               (CFTypeRef*)&subroleRef);
            // NSString* subrole = (__bridge NSString*)subroleRef;
            // if ([subrole isEqual:@"AXStandardWindow"]) {
            //     result.push_back(wid);
            // }
            // }
        }
    }
    return result;
}

std::vector<CGWindowID> space::get_all_window_ids() {
    std::vector<CGWindowID> result;
    CFArrayRef screenDicts = CGSCopyManagedDisplaySpaces(CGSMainConnectionID());
    for (NSDictionary* screen in (__bridge NSArray*)screenDicts) {
        for (NSDictionary* spaceDict in screen[@"Spaces"]) {
            CGSSpaceID sid = [spaceDict[@"id64"] intValue];
            int setTags = 0;
            int clearTags = 0;
            NSArray* windowIds = (__bridge NSArray*)CGSCopyWindowsWithOptionsAndTags(
                CGSMainConnectionID(), 0, (__bridge CFArrayRef) @[ @(sid) ], 2, &setTags,
                &clearTags);

            for (int i = 0; i < windowIds.count; i++) {
                // https://stackoverflow.com/a/74696817/14698275
                id cfNumber = [windowIds objectAtIndex:i];
                CGWindowID wid = [((NSNumber*)cfNumber) intValue];
                CGWindowLevel level;
                CGSGetWindowLevel(CGSMainConnectionID(), wid, &level);
                if (level == CGWindowLevelForKey(kCGNormalWindowLevelKey)) {
                    result.push_back(wid);
                }
            }
        }
    }
    return result;
}

space::~space() {
    CGSHideSpaces(CGSMainConnectionID(), (__bridge CFArrayRef) @[ @(spaceId) ]);
    CGSSpaceDestroy(CGSMainConnectionID(), spaceId);
}
