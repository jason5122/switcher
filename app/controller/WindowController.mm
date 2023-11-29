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

        space = [[CGSSpace alloc] initWithLevel:1];
        [space addWindow:mainWindow];
    }
    return self;
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

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0 * NSEC_PER_SEC), dispatch_get_main_queue(),
                   ^{ [mainView startCaptureSubviews]; });

    CGFloat padding = 20;
    CGFloat innerPadding = 15;
    CGFloat width = 280, height = 175;

    [mainView ahaha];
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

    [mainWindow makeKeyAndOrderFront:nil];
}

- (void)hideWindow {
    if (!_isShown) return;
    else _isShown = false;

    [mainWindow orderOut:nil];
    [mainView stopCaptureSubviews];

    mainView.subviews = [NSArray array];
    mainView->capture_controllers.clear();
    mainView->selectedIndex = 0;
}

@end
