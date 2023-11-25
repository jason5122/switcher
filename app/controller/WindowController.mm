#import "WindowController.h"
#import "extensions/ScreenCaptureKit.h"
#import "private_apis/Accessiblity.h"
#import "util/log_util.h"

@implementation WindowController

- (instancetype)init {
    self = [super init];
    if (self) {
        _isShown = false;
        selectedIndex = 0;

        [self populateInitialApplications];

        int size = windows.size();

        CGFloat width = 320, height = 200;
        CGFloat padding = 20;
        NSRect windowRect =
            NSMakeRect(0, 0, (width + padding) * size + padding, height + padding * 2);
        NSRect screenCaptureRect = NSMakeRect(0, 0, width, height);

        int mask = NSWindowStyleMaskFullSizeContentView;
        nswindow = [[NSWindow alloc] initWithContentRect:windowRect
                                               styleMask:mask
                                                 backing:NSBackingStoreBuffered
                                                   defer:false];
        nswindow.hasShadow = false;
        nswindow.backgroundColor = NSColor.clearColor;

        NSVisualEffectView* visualEffect = [[NSVisualEffectView alloc] init];
        visualEffect.blendingMode = NSVisualEffectBlendingModeBehindWindow;
        visualEffect.material = NSVisualEffectMaterialHUDWindow;
        visualEffect.state = NSVisualEffectStateActive;

        visualEffect.wantsLayer = true;
        visualEffect.layer.cornerRadius = 9.0;

        nswindow.contentView = visualEffect;

        space = [[CGSSpace alloc] initWithLevel:1];
        [space addWindow:nswindow];

        for (int i = 0; i < size; i++) {
            SCWindow* capture_window = [[SCWindow alloc] initWithId:windows[i].wid];
            CaptureView* screenCapture = [[CaptureView alloc] initWithFrame:screenCaptureRect
                                                               targetWindow:capture_window];
            CGFloat x = padding;
            CGFloat y = padding;
            x += (width + padding) * i;
            screenCapture.frameOrigin = CGPointMake(x, y);
            [visualEffect addSubview:screenCapture];

            screen_captures.push_back(screenCapture);
        }
    }
    return self;
}

- (void)populateInitialApplications {
    for (NSRunningApplication* runningApp in NSWorkspace.sharedWorkspace.runningApplications) {
        application app = application(runningApp);

        if ([app.localizedName() isEqual:@"Sublime Text"] ||
            [app.localizedName() isEqual:@"Chromium"]) {
            log_with_type(OS_LOG_TYPE_DEFAULT, app.localizedName(), @"window-controller");

            if (!app.is_xpc()) {
                app.populate_initial_windows();
                applications.push_back(app);

                app.append_windows(windows);
            }
        };
    }
}

- (void)cycleSelectedIndex {
    selectedIndex++;
    if (selectedIndex == windows.size()) selectedIndex = 0;

    log_with_type(OS_LOG_TYPE_DEFAULT,
                  [NSString stringWithFormat:@"index after cycle: %d", selectedIndex],
                  @"window-controller");
}

- (void)focusSelectedIndex {
    if (windows.empty()) return;

    windows[selectedIndex].focus();
}

- (void)showWindow {
    if (_isShown) return;
    else _isShown = true;

    for (CaptureView* screenCapture : screen_captures) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{ [screenCapture startCapture]; });
    }

    // actually center window
    NSSize screenSize = NSScreen.mainScreen.frame.size;
    NSSize panelSize = nswindow.frame.size;
    CGFloat x = fmax(screenSize.width - panelSize.width, 0) * 0.5;
    CGFloat y = fmax(screenSize.height - panelSize.height, 0) * 0.5;
    nswindow.frameOrigin = NSMakePoint(x, y);

    [nswindow makeKeyAndOrderFront:nil];
}

- (void)hideWindow {
    if (!_isShown) return;
    else _isShown = false;

    [nswindow orderOut:nil];

    for (CaptureView* screenCapture : screen_captures) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{ [screenCapture stopCapture]; });
    }
}

@end
