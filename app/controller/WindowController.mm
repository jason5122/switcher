#import "WindowController.h"
#import "controller/CaptureViewController.h"
#import "extensions/ScreenCaptureKit.h"
#import "model/spaces.h"
#import "private_apis/Accessiblity.h"
#import "private_apis/CGSSpace.h"
#import "private_apis/CGSWindows.h"
#import "util/log_util.h"
#import "view/CaptureView.h"

@implementation WindowController

- (instancetype)init {
    self = [super init];
    if (self) {
        _isShown = false;
        selectedIndex = 0;

        // [self populateInitialApplications];

        CGFloat padding = 20;
        CGFloat innerPadding = 15;
        CGFloat width = 280, height = 175;

        mainWindow = [[NSWindow alloc] initWithContentRect:NSZeroRect
                                                 styleMask:NSWindowStyleMaskFullSizeContentView
                                                   backing:NSBackingStoreBuffered
                                                     defer:false];
        mainWindow.hasShadow = false;
        mainWindow.backgroundColor = NSColor.clearColor;

        mainView = [[MainView alloc] initWithCaptureSize:NSMakeSize(width, height)
                                                 padding:padding
                                            innerPadding:innerPadding];
        mainWindow.contentView = mainView;

        // for (CGWindowID wid : get_all_window_ids()) {
        //     cvc1 = [[CaptureViewController alloc] initWithWindowId:wid];
        //     [mainView addSubview:cvc1.view];
        //     mainView->capture_controllers.push_back(cvc1);
        //     break;
        // }

        [mainView ahaha];

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

    CGFloat padding = 20;
    CGFloat innerPadding = 15;
    CGFloat width = 280, height = 175;

    custom_log(OS_LOG_TYPE_DEFAULT, @"window-controller", @"size: %d",
               mainView->capture_controllers.size());

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

    [mainView startCaptureSubviews];
    // [mainWindow.contentView startCaptureSubviews];
    [mainWindow makeKeyAndOrderFront:nil];
}

- (void)hideWindow {
    if (!_isShown) return;
    else _isShown = false;

    [mainWindow orderOut:nil];
    [mainView stopCaptureSubviews];
    // [mainWindow.contentView stopCaptureSubviews];

    // mainView.subviews = [NSArray array];
}

@end
