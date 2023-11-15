#import "CGSSpace.h"

@implementation CGSSpace

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

- (void)dealloc {
    CGSHideSpaces(_CGSDefaultConnection(), (__bridge CFArrayRef) @[ @(self->identifier) ]);
    CGSSpaceDestroy(_CGSDefaultConnection(), self->identifier);
}

@end
