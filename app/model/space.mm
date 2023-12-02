#import "space.h"

space::space(int level) {
    int flag = 0x1;
    identifier = CGSSpaceCreate(_CGSDefaultConnection(), flag, nil);
    CGSSpaceSetAbsoluteLevel(_CGSDefaultConnection(), identifier, level);
    CGSShowSpaces(_CGSDefaultConnection(), (__bridge CFArrayRef) @[ @(identifier) ]);
}

void space::add_window(NSWindow* window) {
    CGSAddWindowsToSpaces(_CGSDefaultConnection(),
                          (__bridge CFArrayRef) @[ @(window.windowNumber) ],
                          (__bridge CFArrayRef) @[ @(identifier) ]);
}

std::vector<CGWindowID> space::get_all_window_ids() {
    std::vector<CGWindowID> result;
    CFArrayRef screenDicts = CGSCopyManagedDisplaySpaces(_CGSDefaultConnection());
    for (NSDictionary* screen in (__bridge NSArray*)screenDicts) {
        NSDictionary* sp = screen[@"Current Space"];
        CGSSpaceID spaceId = [sp[@"id64"] intValue];
        int setTags = 0;
        int clearTags = 0;
        NSArray* windowIds = (__bridge NSArray*)CGSCopyWindowsWithOptionsAndTags(
            _CGSDefaultConnection(), 0, (__bridge CFArrayRef) @[ @(spaceId) ], 2, &setTags,
            &clearTags);

        for (int i = 0; i < windowIds.count; i++) {
            // https://stackoverflow.com/a/74696817/14698275
            id cfNumber = [windowIds objectAtIndex:i];
            CGWindowID wid = [((NSNumber*)cfNumber) intValue];
            CGWindowLevel level;
            CGSGetWindowLevel(_CGSDefaultConnection(), wid, &level);
            if (level == CGWindowLevelForKey(kCGNormalWindowLevelKey)) {
                result.push_back(wid);
            }
        }
    }
    return result;
}

space::~space() {
    CGSHideSpaces(_CGSDefaultConnection(), (__bridge CFArrayRef) @[ @(identifier) ]);
    CGSSpaceDestroy(_CGSDefaultConnection(), identifier);
}
