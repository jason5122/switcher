#import "WindowController.h"
#import "extensions/ScreenCaptureKit.h"
#import "private_apis/Accessiblity.h"
#import "private_apis/SkyLight.h"
#import "util/log_util.h"

@implementation WindowController

- (instancetype)init {
    self = [super init];
    if (self) {
        _isShown = false;
        selectedIndex = 0;

        [self addInitialApplications];

        appPid = applications[0].runningApp.processIdentifier;

        CFArrayRef windowList;
        AXUIElementCopyAttributeValue(applications[0].axUiElement, kAXWindowsAttribute,
                                      (CFTypeRef*)&windowList);

        int count = CFArrayGetCount(windowList);

        CGFloat width = 320, height = 200;
        CGFloat padding = 20;
        NSRect windowRect =
            NSMakeRect(0, 0, (width + padding) * count + padding, height + padding * 2);
        NSRect screenCaptureRect = NSMakeRect(0, 0, width, height);

        int mask = NSWindowStyleMaskFullSizeContentView;
        window = [[NSWindow alloc] initWithContentRect:windowRect
                                             styleMask:mask
                                               backing:NSBackingStoreBuffered
                                                 defer:false];
        window.hasShadow = false;
        window.backgroundColor = NSColor.clearColor;

        NSVisualEffectView* visualEffect = [[NSVisualEffectView alloc] init];
        visualEffect.blendingMode = NSVisualEffectBlendingModeBehindWindow;
        visualEffect.material = NSVisualEffectMaterialHUDWindow;
        visualEffect.state = NSVisualEffectStateActive;

        visualEffect.wantsLayer = true;
        visualEffect.layer.cornerRadius = 9.0;

        window.contentView = visualEffect;

        space = [[CGSSpace alloc] initWithLevel:1];
        [space addWindow:window];

        log_with_type(
            OS_LOG_TYPE_DEFAULT,
            [NSString stringWithFormat:@"window count: %ld", CFArrayGetCount(windowList)],
            @"window-controller");

        for (int i = 0; i < count; i++) {
            AXUIElementRef windowRef = (AXUIElementRef)CFArrayGetValueAtIndex(windowList, i);
            CGWindowID wid = CGWindowID();
            _AXUIElementGetWindow(windowRef, &wid);

            log_with_type(OS_LOG_TYPE_DEFAULT, [NSString stringWithFormat:@"wid: %d", wid],
                          @"window-controller");

            SCWindow* capture_window = [[SCWindow alloc] initWithId:wid];

            CaptureView* screenCapture = [[CaptureView alloc] initWithFrame:screenCaptureRect
                                                               targetWindow:capture_window];
            CGFloat x = padding;
            CGFloat y = padding;
            x += (width + padding) * i;
            screenCapture.frameOrigin = CGPointMake(x, y);
            [visualEffect addSubview:screenCapture];

            screen_captures.push_back(screenCapture);
            axui_refs.push_back(windowRef);
        }
    }
    return self;
}

- (void)addInitialApplications {
    for (NSRunningApplication* runningApp in NSWorkspace.sharedWorkspace.runningApplications) {
        application app = application(runningApp);
        if (![app.localizedName() isEqual:@"Sublime Text"]) continue;
        if (!app.is_xpc()) applications.push_back(app);
    }
}

- (void)cycleSelectedIndex {
    selectedIndex++;
    if (selectedIndex == axui_refs.size()) selectedIndex = 0;

    log_with_type(OS_LOG_TYPE_DEFAULT,
                  [NSString stringWithFormat:@"index after cycle: %d", selectedIndex],
                  @"window-controller");
}

- (void)focusSelectedIndex {
    if (axui_refs.empty()) return;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    ProcessSerialNumber psn = ProcessSerialNumber();
    CGWindowID wid = CGWindowID();
    _AXUIElementGetWindow(axui_refs[selectedIndex], &wid);
    GetProcessForPID(appPid, &psn);
#pragma clang diagnostic pop

    // https://github.com/koekeishiya/yabai/issues/1772#issuecomment-1649919480
    _SLPSSetFrontProcessWithOptions(&psn, 0, kSLPSNoWindows);
    AXUIElementPerformAction(axui_refs[selectedIndex], kAXRaiseAction);
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
    NSSize panelSize = window.frame.size;
    CGFloat x = fmax(screenSize.width - panelSize.width, 0) * 0.5;
    CGFloat y = fmax(screenSize.height - panelSize.height, 0) * 0.5;
    window.frameOrigin = NSMakePoint(x, y);

    [window makeKeyAndOrderFront:nil];
}

- (void)hideWindow {
    if (!_isShown) return;
    else _isShown = false;

    [window orderOut:nil];

    for (CaptureView* screenCapture : screen_captures) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{ [screenCapture stopCapture]; });
    }
}

@end
