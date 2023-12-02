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
        apps.window_map[wid].focus();
    }
}

- (void)showWindow:(bool)onlyActiveApp {
    if (_shown) return;
    else _shown = true;

    pid_t frontmost_pid = NSWorkspace.sharedWorkspace.frontmostApplication.processIdentifier;

    std::vector<CGWindowID> window_ids;
    for (CGWindowID windowId : space::get_all_window_ids()) {
        if (apps.window_map.count(windowId)) {
            pid_t pid;
            AXUIElementGetPid(apps.window_map[windowId].windowRef, &pid);
            if (onlyActiveApp && pid != frontmost_pid) continue;

            CFStringRef subroleRef;
            AXUIElementCopyAttributeValue(apps.window_map[windowId].windowRef, kAXSubroleAttribute,
                                          (CFTypeRef*)&subroleRef);
            NSString* subrole = (__bridge NSString*)subroleRef;
            if ([subrole isEqual:@"AXStandardWindow"]) {
                window_ids.push_back(windowId);
            }
        }
    }
    [mainView populateWithWindowIds:window_ids];
    [mainView startCaptureSubviews];

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
