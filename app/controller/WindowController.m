#import "controller/WindowController.h"

@implementation WindowController

- (instancetype)initWithBounds:(CGRect)bounds {
    // int mask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
    //            NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable;
    int mask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
               NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable |
               NSWindowStyleMaskFullSizeContentView;

    NSWindow* window = [[NSWindow alloc] initWithContentRect:bounds
                                                   styleMask:mask
                                                     backing:NSBackingStoreBuffered
                                                       defer:YES];

    id bundleInfo = [[NSBundle mainBundle] infoDictionary];
    NSString* appName = [bundleInfo objectForKey:@"CFBundleName"];
    // [window setTitle:appName];
    [window center];

    // mimic Sublime Text Adaptive theme
    window.titlebarAppearsTransparent = true;
    window.backgroundColor = NSColor.whiteColor;

    [window disableCursorRects];

    self = [super initWithWindow:window];
    if (self) {
        // required for windowDidResize() to work
        self.window.delegate = self;
    }
    return self;
}

@end
