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

std::vector<CGWindowID> space::get_all_window_ids_new() {
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

std::vector<CGWindowID> space::get_all_window_ids() {
    std::vector<CGWindowID> result;
    // CFArrayRef screenDicts = CGSCopyManagedDisplaySpaces(CGSMainConnectionID());
    // for (NSDictionary* screen in (__bridge NSArray*)screenDicts) {
    //     NSDictionary* sp = screen[@"Current Space"];
    //     CGSSpaceID sid = [sp[@"id64"] intValue];
    //     int setTags = 0;
    //     int clearTags = 0;
    //     NSArray* windowIds = (__bridge NSArray*)CGSCopyWindowsWithOptionsAndTags(
    //         CGSMainConnectionID(), 0, (__bridge CFArrayRef) @[ @(sid) ], 2, &setTags,
    //         &clearTags);

    //     for (int i = 0; i < windowIds.count; i++) {
    //         // https://stackoverflow.com/a/74696817/14698275
    //         id cfNumber = [windowIds objectAtIndex:i];
    //         CGWindowID wid = [((NSNumber*)cfNumber) intValue];
    //         CGWindowLevel level;
    //         CGSGetWindowLevel(CGSMainConnectionID(), wid, &level);
    //         if (level == CGWindowLevelForKey(kCGNormalWindowLevelKey)) {
    //             result.push_back(wid);
    //         }
    //     }
    // }
    CGSSpaceID sid = CGSGetActiveSpace(CGSMainConnectionID());
    int setTags = 0;
    int clearTags = 0;
    NSArray* windowIds = (__bridge NSArray*)CGSCopyWindowsWithOptionsAndTags(
        CGSMainConnectionID(), 0, (__bridge CFArrayRef) @[ @(sid) ], 2, &setTags, &clearTags);

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
    return result;
}

space::~space() {
    CGSHideSpaces(CGSMainConnectionID(), (__bridge CFArrayRef) @[ @(spaceId) ]);
    CGSSpaceDestroy(CGSMainConnectionID(), spaceId);
}
