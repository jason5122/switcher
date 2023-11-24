#import "WindowController.h"
#import "extensions/ScreenCaptureKit.h"
#import "private_apis/AXUIElement.h"
#import "util/log_util.h"
#import "view/CaptureView.h"
#import <vector>

struct CppMembers {
    std::vector<CaptureView*> screen_captures;
};

@implementation WindowController

- (instancetype)init {
    self = [super init];
    if (self) {
        cpp = new CppMembers;

        _isShown = false;

        [self observeApplications];

        CFArrayRef windowList;
        AXUIElementCopyAttributeValue(axUiElement, kAXWindowsAttribute, (CFTypeRef*)&windowList);

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
            cpp->screen_captures.push_back(screenCapture);

            // AXUIElementPerformAction(windowRef, kAXRaiseAction);
        }
    }
    return self;
}

- (void)observeApplications {
    NSRunningApplication* sublime;

    NSArray<NSRunningApplication*>* apps = NSWorkspace.sharedWorkspace.runningApplications;
    for (NSRunningApplication* app in apps) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        ProcessSerialNumber psn = ProcessSerialNumber();
        ProcessInfoRec info = ProcessInfoRec();
        GetProcessForPID(app.processIdentifier, &psn);
        GetProcessInformation(&psn, &info);
#pragma clang diagnostic pop

        if (info.processType == 'XPC!') continue;
        if ([app.localizedName isEqual:@"Sublime Text"]) sublime = app;
    }

    log_with_type(OS_LOG_TYPE_DEFAULT, sublime.localizedName, @"window-controller");
    pid_t pid = sublime.processIdentifier;
    AXObserverRef axObserver;
    axUiElement = AXUIElementCreateApplication(pid);

    // WARNING: starting SCStream triggers kAXWindowCreatedNotification (one per captured window)
    AXObserverCreate(
        pid,
        [](AXObserverRef observer, AXUIElementRef element, CFStringRef notificationName,
           void* refCon) {
            CGWindowID wid = CGWindowID();
            _AXUIElementGetWindow(element, &wid);
            if (CFEqual(notificationName, kAXWindowCreatedNotification)) {
                log_with_type(OS_LOG_TYPE_DEFAULT,
                              [NSString stringWithFormat:@"window created: %d", wid],
                              @"window-controller");
            }
        },
        &axObserver);
    AXObserverAddNotification(axObserver, axUiElement, kAXWindowCreatedNotification, nil);
    CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(axObserver),
                       kCFRunLoopDefaultMode);
}

- (void)showWindow {
    if (_isShown) return;
    else _isShown = true;

    for (CaptureView* screenCapture : cpp->screen_captures) {
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

    for (CaptureView* screenCapture : cpp->screen_captures) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{ [screenCapture stopCapture]; });
    }
}

@end
