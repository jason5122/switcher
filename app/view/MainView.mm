#import "MainView.h"
#import "view/CaptureView.h"

@implementation MainView

- (instancetype)initWithCaptureSize:(CGSize)theSize
                            padding:(CGFloat)thePadding
                       innerPadding:(CGFloat)theInnerPadding
                   titleTextPadding:(CGFloat)theTitleTextPadding {
    self = [super init];
    if (self) {
        size = theSize;
        padding = thePadding;
        innerPadding = theInnerPadding;
        titleTextPadding = theTitleTextPadding;
        selectedIndex = 0;

        self.material = NSVisualEffectMaterialHUDWindow;
        self.state = NSVisualEffectStateActive;
        self.wantsLayer = true;
        self.layer.cornerRadius = 9.0;
    }
    return self;
}

- (void)populateWithWindowIds:(std::vector<CGWindowID>)windowIds {
    for (CGWindowID wid : windowIds) {
        CaptureViewController* captureViewController =
            [[CaptureViewController alloc] initWithWindowId:wid
                                                       size:size
                                               innerPadding:innerPadding
                                           titleTextPadding:titleTextPadding];

        CGFloat x = padding;
        CGFloat y = padding;
        x += (size.width + padding + innerPadding) * self.subviews.count;
        captureViewController.view.frameOrigin = CGPointMake(x, y);

        [self addSubview:captureViewController.view];
        capture_controllers.push_back(captureViewController);
    }
}

- (void)updateWithWindowIds:(std::vector<CGWindowID>)windowIds {
    int min_size = std::min(capture_controllers.size(), windowIds.size());
    for (int i = 0; i < min_size; i++) {
        [capture_controllers[i] updateWithWindowId:windowIds[i]];
    }
}

- (void)startCaptureSubviews {
    for (CaptureViewController* controller : capture_controllers) {
        dispatch_async(dispatch_get_main_queue(), ^{ [controller.captureView startCapture]; });
    }
}

- (void)stopCaptureSubviews {
    for (CaptureViewController* controller : capture_controllers) {
        dispatch_async(dispatch_get_main_queue(), ^{ [controller.captureView stopCapture]; });
    }
}

- (void)cycleSelectedIndex {
    if (capture_controllers.empty()) return;

    [capture_controllers[selectedIndex] unhighlight];
    selectedIndex++;
    if (selectedIndex == capture_controllers.size()) selectedIndex = 0;
    [capture_controllers[selectedIndex] highlight];
}

- (CGWindowID)getSelectedWindowId {
    if (capture_controllers.empty()) return -1;

    return capture_controllers[selectedIndex].wid;
}

- (void)reset {
    // self.subviews = [NSArray array];
    // capture_controllers.clear();
    [capture_controllers[selectedIndex] unhighlight];
    selectedIndex = 0;
}

@end
