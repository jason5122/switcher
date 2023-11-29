#import "WindowController.h"
#import "controller/CaptureViewController.h"
#import "extensions/ScreenCaptureKit.h"
#import "private_apis/Accessiblity.h"
#import "private_apis/CGSSpace.h"
#import "private_apis/CGSWindows.h"
#import "util/log_util.h"
#import "view/CaptureView.h"

@implementation WindowController

- (void)listWindowsExperiment {
    // CFArrayRef screenDicts = CGSCopyManagedDisplaySpaces(_CGSDefaultConnection());
    // for (NSDictionary* dict in (__bridge NSArray*)screenDicts) {
    //     NSNumber* spaceId = dict[@"Spaces"][0][@"id64"];
    //     int setTags = 0;
    //     int clearTags = 0;
    //     NSArray* windowIds = (__bridge NSArray*)CGSCopyWindowsWithOptionsAndTags(
    //         _CGSDefaultConnection(), 0, (__bridge CFArrayRef) @[ spaceId ], 2, &setTags,
    //         &clearTags);

    //     // custom_log(OS_LOG_TYPE_DEFAULT, @"window-controller", @"%@", windowIds);

    //     for (NSNumber* number in windowIds) {
    //         CGWindowID wid = [number unsignedIntValue];
    //         CGWindowLevel level;
    //         CGSGetWindowLevel(_CGSDefaultConnection(), wid, &level);

    //         if (level == CGWindowLevelForKey(kCGNormalWindowLevelKey)) {
    //             custom_log(OS_LOG_TYPE_DEFAULT, @"window-controller", @"%d: level %d", wid,
    //             level);
    //         }
    //     }
    // }

    int setTags = 0;
    int clearTags = 0;
    NSArray* windowIds = (__bridge NSArray*)CGSCopyWindowsWithOptionsAndTags(
        _CGSDefaultConnection(), 0,
        (__bridge CFArrayRef) @[ @(CGSManagedDisplayGetCurrentSpace(
            _CGSDefaultConnection(), kCGSPackagesMainDisplayIdentifier)) ],
        2, &setTags, &clearTags);

    for (NSNumber* number in windowIds) {
        CGWindowID wid = [number unsignedIntValue];
        CGWindowLevel level;
        CGSGetWindowLevel(_CGSDefaultConnection(), wid, &level);

        if (level == CGWindowLevelForKey(kCGNormalWindowLevelKey)) {
            custom_log(OS_LOG_TYPE_DEFAULT, @"window-controller", @"%d: level %d", wid, level);
        }
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isShown = false;
        selectedIndex = 0;

        [self populateInitialApplications];

        int size = windows.size();

        CGFloat width = 280, height = 175;
        CGFloat padding = 20;
        // CGFloat padding = 0;
        NSRect windowRect =
            NSMakeRect(0, 0, (width + padding) * size + padding, height + padding * 2);

        int mask = NSWindowStyleMaskFullSizeContentView;
        mainWindow = [[NSWindow alloc] initWithContentRect:windowRect
                                                 styleMask:mask
                                                   backing:NSBackingStoreBuffered
                                                     defer:false];
        mainWindow.hasShadow = false;
        mainWindow.backgroundColor = NSColor.clearColor;

        NSVisualEffectView* mainView = [[NSVisualEffectView alloc] init];
        // mainView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
        mainView.material = NSVisualEffectMaterialHUDWindow;
        // mainView.material = NSVisualEffectMaterialSelection;
        mainView.state = NSVisualEffectStateActive;
        mainView.wantsLayer = true;
        mainView.layer.cornerRadius = 9.0;

        // NSStackView* mainView = [[NSStackView alloc] init];
        // // NSView* mainView = [[NSView alloc] init];
        // mainView.wantsLayer = true;
        // mainView.layer.borderColor = CGColorGetConstantColor(kCGColorBlack);
        // mainView.layer.borderWidth = 5;
        // mainView.layer.backgroundColor =
        //     [NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:0.5f].CGColor;
        // ;

        space = [[CGSSpace alloc] initWithLevel:1];
        [space addWindow:mainWindow];

        for (int i = 0; i < size; i++) {
            custom_log(OS_LOG_TYPE_DEFAULT, @"window-controller", @"%d: %@", windows[i].wid,
                       windows[i].title);

            CaptureViewController* captureViewController =
                [[CaptureViewController alloc] initWithWindow:windows[i]];
            CGFloat x = padding;
            CGFloat y = padding;
            x += (width + padding) * i;
            // captureViewController.view.frame =
            //     CGRectInset(captureViewController.view.frame, 10, 10);
            captureViewController.view.frameOrigin = CGPointMake(x, y);
            // [mainView addSubview:captureViewController.view];

            // NSStackView* blurView = [[NSStackView alloc] init];
            // NSVisualEffectView* blurView = [[NSVisualEffectView alloc] init];
            // blurView.frame = CGRectMake(x, y, 320, 200);
            // NSView* blurView = [[NSView alloc] initWithFrame:CGRectMake(0, 0, 600, 600)];
            // blurView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
            // blurView.material = NSVisualEffectMaterialSelection;
            // blurView.state = NSVisualEffectStateActive;
            // blurView.wantsLayer = true;
            // blurView.layer.cornerRadius = 9.0;

            // NSTextField* titleText = [NSTextField labelWithString:windows[i].title];
            // titleText.frameOrigin = CGPointMake(x, y - 20);
            // titleText.frameSize = CGSizeMake(width, 20);
            // titleText.alignment = NSTextAlignmentCenter;
            // [mainView addSubview:titleText];

            // [blurView addSubview:captureViewController.view];
            // [mainView addSubview:blurView];
            [mainView addSubview:captureViewController.view];

            capture_controllers.push_back(captureViewController);
        }

        mainWindow.contentView = mainView;

        // TODO: experimental; maybe remove
        mainWindow.ignoresMouseEvents = true;
    }
    return self;
}

- (void)populateInitialApplications {
    for (NSRunningApplication* runningApp in NSWorkspace.sharedWorkspace.runningApplications) {
        application app = application(runningApp);

        if ([app.localizedName() isEqual:@"Sublime Text"] ||
            [app.localizedName() isEqual:@"Chromium"] ||
            [app.localizedName() isEqual:@"Alacritty"]) {
            custom_log(OS_LOG_TYPE_DEFAULT, @"window-controller", app.localizedName());

            if (!app.is_xpc()) {
                app.populate_initial_windows();
                applications.push_back(app);

                app.append_windows(windows);
            }
        };
    }
}

- (void)cycleSelectedIndex {
    if (capture_controllers.empty()) return;

    [capture_controllers[selectedIndex] unhighlight];

    selectedIndex++;
    if (selectedIndex == windows.size()) selectedIndex = 0;

    [capture_controllers[selectedIndex] highlight];

    custom_log(OS_LOG_TYPE_DEFAULT, @"window-controller", @"index after cycle: %d", selectedIndex);
}

- (void)focusSelectedIndex {
    if (windows.empty()) return;

    windows[selectedIndex].focus();

    // window temp = windows[selectedIndex];
    // windows.erase(windows.begin() + selectedIndex);
    // windows.insert(windows.begin(), temp);

    // selectedIndex = 0;
}

- (void)showWindow {
    if (_isShown) return;
    else _isShown = true;

    [self listWindowsExperiment];  // TODO: debug; remove

    for (CaptureViewController* controller : capture_controllers) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{ [controller startCapture]; });
    }

    // actually center window
    NSSize screenSize = NSScreen.mainScreen.frame.size;
    NSSize panelSize = mainWindow.frame.size;
    CGFloat x = fmax(screenSize.width - panelSize.width, 0) * 0.5;
    CGFloat y = fmax(screenSize.height - panelSize.height, 0) * 0.5;
    mainWindow.frameOrigin = NSMakePoint(x, y);

    [mainWindow makeKeyAndOrderFront:nil];
}

- (void)hideWindow {
    if (!_isShown) return;
    else _isShown = false;

    [mainWindow orderOut:nil];

    for (CaptureViewController* controller : capture_controllers) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{ [controller stopCapture]; });
    }
}

@end
