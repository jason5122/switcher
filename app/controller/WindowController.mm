#import "WindowController.h"
#import "extensions/NSWindow+ActuallyCenter.h"
#import "model/space.h"

@implementation WindowController

- (instancetype)initWithSize:(CGSize)theSize
                     padding:(CGFloat)thePadding
                innerPadding:(CGFloat)theInnerPadding
            titleTextPadding:(CGFloat)theTitleTextPadding {
    self = [super init];
    if (self) {
        size = theSize;
        padding = thePadding;
        innerPadding = theInnerPadding;
        titleTextPadding = theTitleTextPadding;
        _shown = false;
        numDelays = 0;

        self.window = [[NSWindow alloc] initWithContentRect:NSZeroRect
                                                  styleMask:NSWindowStyleMaskFullSizeContentView
                                                    backing:NSBackingStoreBuffered
                                                      defer:false];
        self.window.hasShadow = false;
        self.window.backgroundColor = NSColor.clearColor;

        mainView = [[MainView alloc] initWithCaptureSize:theSize
                                                 padding:thePadding
                                            innerPadding:theInnerPadding
                                        titleTextPadding:theTitleTextPadding];
        self.window.contentView = mainView;

        sp = new space(1);
        sp->add_window(self.window);

        apps.populate_with_window_ids();

        std::vector<CGWindowID> window_ids = space::get_all_valid_window_ids(apps.window_map);
        // std::vector<CGWindowID> window_ids = space::get_all_window_ids();
        [mainView populateWithWindowIds:window_ids];
    }
    return self;
}

- (void)cycleSelectedIndex {
    [self.window.contentView cycleSelectedIndex];
}

- (void)focusSelectedIndex {
    CGWindowID wid = [self.window.contentView getSelectedWindowId];
    if (apps.window_map.count(wid)) {
        apps.window_map[wid].focus();
    }
}

- (void)showWindow:(bool)onlyActiveApp {
    if (_shown) return;
    else _shown = true;

    apps.refresh_window_ids();

    std::vector<CGWindowID> window_ids = space::get_all_valid_window_ids(apps.window_map);
    // std::vector<CGWindowID> window_ids = space::get_all_window_ids();
    [mainView updateWithWindowIds:window_ids];

    [mainView startCaptureSubviews];

    NSSize contentSize =
        NSMakeSize((size.width + padding + innerPadding) * self.window.contentView.subviews.count +
                       padding + innerPadding,
                   size.height + (padding + innerPadding) * 2 + titleTextPadding);
    [self.window setContentSize:contentSize];

    numDelays++;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 500 * NSEC_PER_MSEC),
                   dispatch_get_main_queue(), ^{
                     // Multiple delayed triggers should only show when the latest delay ends.
                     if (numDelays == 1 && _shown) {
                         [self.window actuallyCenter];
                         [self.window makeKeyAndOrderFront:nil];
                     }
                     numDelays--;
                   });
}

- (void)hideWindow {
    if (!_shown) return;
    else _shown = false;

    [self.window orderOut:nil];

    [mainView stopCaptureSubviews];
    [mainView reset];
}

@end
