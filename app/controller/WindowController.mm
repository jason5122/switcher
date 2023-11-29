#import "WindowController.h"
#import "controller/CaptureViewController.h"
#import "extensions/NSWindow+ActuallyCenter.h"
#import "extensions/ScreenCaptureKit.h"
#import "model/spaces.h"
#import "private_apis/Accessiblity.h"
#import "private_apis/CGSSpace.h"
#import "private_apis/CGSWindows.h"
#import "util/log_util.h"
#import "view/CaptureView.h"

@implementation WindowController

- (instancetype)initWithSize:(CGSize)theSize
                     padding:(CGFloat)thePadding
                innerPadding:(CGFloat)theInnerPadding {
    self = [super init];
    if (self) {
        _shown = false;
        selectedIndex = 0;

        size = theSize;
        padding = thePadding;
        innerPadding = theInnerPadding;

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

        space = [[CGSSpace alloc] initWithLevel:1];
        [space addWindow:self.window];
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

    // TODO: why does this crash without a dispatch?
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0 * NSEC_PER_SEC), dispatch_get_main_queue(),
                   ^{ [mainView startCaptureSubviews]; });

    [mainView ahaha];
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

    mainView.subviews = [NSArray array];
    mainView->capture_controllers.clear();
    mainView->selectedIndex = 0;
}

@end
