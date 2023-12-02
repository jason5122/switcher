#import "WindowController.h"
#import "extensions/NSWindow+ActuallyCenter.h"
#import "model/space.h"
#import "private_apis/SkyLight.h"
#import "util/log_util.h"

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
    }
    return self;
}

- (void)cycleSelectedIndex {
    [self.window.contentView cycleSelectedIndex];
}

- (void)focusSelectedIndex {
    CGWindowID wid = [self.window.contentView getSelectedWindowId];
    if (apps.window_map.count(wid)) {
        // apps.window_map[wid].focus();

        // _SLPSSetFrontProcessWithOptions(&apps.window_map[wid].psn, 0, kSLPSNoWindows);
        // AXUIElementPerformAction(apps.finalRef, kAXRaiseAction);

        // AXUIElementPerformAction(apps.aaa.back(), kAXRaiseAction);

        // apps.SHIT(nullptr);

        if (apps.ay == nullptr) {
            custom_log(OS_LOG_TYPE_DEFAULT, @"applications", @":(");
        } else {
            custom_log(OS_LOG_TYPE_DEFAULT, @"applications", @"after: %lu", CFHash(apps.ay));
            // AXUIElementPerformAction(apps.ay, kAXRaiseAction);
        }

        // std::string s = "yes [";
        // for (const auto& [wid, win_el] : apps.window_map) {
        //     // custom_log(OS_LOG_TYPE_DEFAULT, @"applications", @"%u -> [%lu, {%u %u}]", wid,
        //     //            CFHash(apps.window_map[wid].windowRef),
        //     //            apps.window_map[wid].psn.highLongOfPSN,
        //     //            apps.window_map[wid].psn.lowLongOfPSN);
        //     // CFHash(apps.window_map[wid].windowRef);
        //     s += std::to_string(CFHash(apps.ref_map[wid])) + ", ";
        // }
        // s += ']';
        // custom_log(OS_LOG_TYPE_DEFAULT, @"applications", @"%s", s.c_str());
    }
}

- (void)showWindow {
    if (_shown) return;
    else _shown = true;

    // custom_log(OS_LOG_TYPE_DEFAULT, @"applications", @"window_map %d", apps.window_map.size());
    // custom_log(OS_LOG_TYPE_DEFAULT, @"applications", @"window_ref_map %d",
    //            apps.window_ref_map.size());

    std::vector<CGWindowID> window_ids;
    for (CGWindowID windowId : space::get_all_window_ids()) {
        if (apps.window_map.count(windowId)) window_ids.push_back(windowId);
    }
    [mainView populateWithWindowIds:window_ids];

    // TODO: why does this crash without a dispatch?
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0 * NSEC_PER_SEC), dispatch_get_main_queue(),
                   ^{ [mainView startCaptureSubviews]; });
    // [mainView startCaptureSubviews];

    NSSize contentSize =
        NSMakeSize((size.width + padding + innerPadding) * self.window.contentView.subviews.count +
                       padding + innerPadding,
                   size.height + (padding + innerPadding) * 2 + titleTextPadding);
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
