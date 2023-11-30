#import "WindowController.h"
#import "extensions/NSWindow+ActuallyCenter.h"

@implementation WindowController

- (instancetype)initWithSize:(CGSize)theSize
                     padding:(CGFloat)thePadding
                innerPadding:(CGFloat)theInnerPadding {
    self = [super init];
    if (self) {
        size = theSize;
        padding = thePadding;
        innerPadding = theInnerPadding;
        _shown = false;

        self.window = [[NSWindow alloc] initWithContentRect:NSZeroRect
                                                  styleMask:NSWindowStyleMaskFullSizeContentView
                                                    backing:NSBackingStoreBuffered
                                                      defer:false];
        self.window.hasShadow = false;
        self.window.backgroundColor = NSColor.clearColor;

        mainView = [[MainView alloc] initWithCaptureSize:theSize
                                                 padding:thePadding
                                            innerPadding:theInnerPadding];
        self.window.contentView = mainView;

        sp = new space(1);
        sp->add_window(self.window);
    }
    return self;
}

- (void)cycleSelectedIndex {
    [self.window.contentView cycleSelectedIndex];
}

- (void)focusSelectedIndex {
    // [self.window.contentView focusSelectedIndex];
}

- (void)showWindow {
    if (_shown) return;
    else _shown = true;

    [mainView populateWithCurrentWindows];

    // TODO: why does this crash without a dispatch?
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0 * NSEC_PER_SEC), dispatch_get_main_queue(),
                   ^{ [mainView startCaptureSubviews]; });
    // [mainView startCaptureSubviews];

    NSSize contentSize =
        NSMakeSize((size.width + padding + innerPadding) * self.window.contentView.subviews.count +
                       padding + innerPadding,
                   size.height + (padding + innerPadding) * 2);
    [self.window setContentSize:contentSize];
    [self.window actuallyCenter];
    [self.window makeKeyAndOrderFront:nil];
}

- (void)hideWindow {
    if (!_shown) return;
    else _shown = false;

    [self.window orderOut:nil];

    [mainView stopCaptureSubviews];
    [mainView reset];
}

@end
