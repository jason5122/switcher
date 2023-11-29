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
            [mainWindow.contentView addCaptureSubviewId:wid];
        }
    }

    CGFloat padding = 20;
    CGFloat innerPadding = 15;
    CGFloat width = 280, height = 175;
    NSSize contentSize =
        NSMakeSize((width + padding + innerPadding) * mainWindow.contentView.subviews.count +
                       padding + innerPadding,
                   height + (padding + innerPadding) * 2);
    [mainWindow setContentSize:contentSize];

    // actually center window
    NSSize screenSize = NSScreen.mainScreen.frame.size;
    NSSize panelSize = mainWindow.frame.size;
    CGFloat x = fmax(screenSize.width - panelSize.width, 0) * 0.5;
    CGFloat y = fmax(screenSize.height - panelSize.height, 0) * 0.5;
    mainWindow.frameOrigin = NSMakePoint(x, y);
}

- (void)consistentSpaceExperiment {
    CFArrayRef screenDicts = CGSCopyManagedDisplaySpaces(_CGSDefaultConnection());
    for (NSDictionary* dict in (__bridge NSArray*)screenDicts) {
        // custom_log(OS_LOG_TYPE_DEFAULT, @"window-controller", @"%@", dict);
    }

    int setTags = 0;
    int clearTags = 0;
    NSArray* windowIds = (__bridge NSArray*)CGSCopyWindowsWithOptionsAndTags(
        _CGSDefaultConnection(), 0,
        (__bridge CFArrayRef) @[ @(CGSManagedDisplayGetCurrentSpace(
            _CGSDefaultConnection(), kCGSPackagesMainDisplayIdentifier)) ],
        2, &setTags, &clearTags);

    for (int i = 0; i < windowIds.count; i++) {
        // https://stackoverflow.com/a/74696817/14698275
        id cfNumber = [windowIds objectAtIndex:i];
        CGWindowID wid = [((NSNumber*)cfNumber) intValue];
        custom_log(OS_LOG_TYPE_DEFAULT, @"window-controller", @"%d", wid);

        [mainView addCaptureSubviewId:wid];
    }
}

// TODO: this is still inconsistent... do more experiments with CGSCopyWindowsWithOptionsAndTags()
- (void)aha {
    int setTags = 0;
    int clearTags = 0;
    NSArray* windowIds = (__bridge NSArray*)CGSCopyWindowsWithOptionsAndTags(
        _CGSDefaultConnection(), 0,
        (__bridge CFArrayRef) @[ @(CGSManagedDisplayGetCurrentSpace(
            _CGSDefaultConnection(), kCGSPackagesMainDisplayIdentifier)) ],
        2, &setTags, &clearTags);
    for (int i = 0; i < windowIds.count; i++) {
        // https://stackoverflow.com/a/74696817/14698275
        id cfNumber = [windowIds objectAtIndex:i];
        CGWindowID wid = [((NSNumber*)cfNumber) intValue];
        custom_log(OS_LOG_TYPE_DEFAULT, @"window-controller", @"%d", wid);

        CGWindowLevel level;
        CGSGetWindowLevel(_CGSDefaultConnection(), wid, &level);
        if (level == CGWindowLevelForKey(kCGNormalWindowLevelKey)) {
            [mainView addCaptureSubviewId:wid];
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

        CGFloat padding = 20;
        CGFloat innerPadding = 15;
        CGFloat width = 280, height = 175;

        int mask = NSWindowStyleMaskFullSizeContentView;
        mainWindow = [[NSWindow alloc] initWithContentRect:NSZeroRect
                                                 styleMask:mask
                                                   backing:NSBackingStoreBuffered
                                                     defer:false];
        mainWindow.hasShadow = false;
        mainWindow.backgroundColor = NSColor.clearColor;

        mainView = [[MainView alloc] initWithCaptureSize:NSMakeSize(width, height)
                                                 padding:padding
                                            innerPadding:innerPadding];

        for (int i = 0; i < size; i++) {
            custom_log(OS_LOG_TYPE_DEFAULT, @"window-controller", @"%d: %@", windows[i].wid,
                       windows[i].title);
            // [mainView addCaptureSubview:windows[i]];
            // [mainView addCaptureSubviewId:windows[i].wid];
        }

        [self aha];

        NSSize contentSize = NSMakeSize(
            (width + padding + innerPadding) * mainView.subviews.count + padding + innerPadding,
            height + (padding + innerPadding) * 2);
        [mainWindow setContentSize:contentSize];

        mainWindow.contentView = mainView;

        // actually center window
        NSSize screenSize = NSScreen.mainScreen.frame.size;
        NSSize panelSize = mainWindow.frame.size;
        CGFloat x = fmax(screenSize.width - panelSize.width, 0) * 0.5;
        CGFloat y = fmax(screenSize.height - panelSize.height, 0) * 0.5;
        mainWindow.frameOrigin = NSMakePoint(x, y);

        space = [[CGSSpace alloc] initWithLevel:1];
        [space addWindow:mainWindow];
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
    [((MainView*)mainWindow.contentView) cycleSelectedIndex];
}

- (void)focusSelectedIndex {
    // [((MainView*)mainWindow.contentView) focusSelectedIndex];
}

- (void)showWindow {
    if (_isShown) return;
    else _isShown = true;

    // [self listWindowsExperiment];  // TODO: debug; remove
    // [self consistentSpaceExperiment];

    [mainWindow.contentView startCaptureSubviews];
    [mainWindow makeKeyAndOrderFront:nil];
}

- (void)hideWindow {
    if (!_isShown) return;
    else _isShown = false;

    [mainWindow orderOut:nil];
    [mainWindow.contentView stopCaptureSubviews];

    // mainWindow.contentView.subviews = [NSArray array];
}

@end
