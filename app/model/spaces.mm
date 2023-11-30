#import "spaces.h"

@implementation Space

- (instancetype)initWithLevel:(int)level {
    self = [super init];
    if (self) {
        int flag = 0x1;
        identifier = CGSSpaceCreate(_CGSDefaultConnection(), flag, nil);
        CGSSpaceSetAbsoluteLevel(_CGSDefaultConnection(), self->identifier, level);
        CGSShowSpaces(_CGSDefaultConnection(), (__bridge CFArrayRef) @[ @(self->identifier) ]);
    }
    return self;
}

- (void)addWindow:(NSWindow*)window {
    CGSAddWindowsToSpaces(_CGSDefaultConnection(),
                          (__bridge CFArrayRef) @[ @(window.windowNumber) ],
                          (__bridge CFArrayRef) @[ @(self->identifier) ]);
}

+ (std::vector<CGWindowID>)getAllWindowIds {
    std::vector<CGWindowID> result;
    CFArrayRef screenDicts = CGSCopyManagedDisplaySpaces(_CGSDefaultConnection());
    for (NSDictionary* screen in (__bridge NSArray*)screenDicts) {
        for (NSDictionary* sp in screen[@"Spaces"]) {
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
    }
    return result;
}

- (void)dealloc {
    CGSHideSpaces(_CGSDefaultConnection(), (__bridge CFArrayRef) @[ @(self->identifier) ]);
    CGSSpaceDestroy(_CGSDefaultConnection(), self->identifier);
}

@end
