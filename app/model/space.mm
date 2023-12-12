#import "extensions/AXUIElement.h"
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

space::~space() {
    CGSHideSpaces(CGSMainConnectionID(), (__bridge CFArrayRef) @[ @(spaceId) ]);
    CGSSpaceDestroy(CGSMainConnectionID(), spaceId);
}
