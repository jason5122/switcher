#import "MainView.h"

@implementation MainView

- (instancetype)initWithCaptureSize:(CGSize)theSize
                            padding:(CGFloat)thePadding
                       innerPadding:(CGFloat)theInnerPadding
                   titleTextPadding:(CGFloat)theTitleTextPadding {
    self = [super init];
    if (self) {
        actual_count = 0;
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
        [self appendViewControllerWithId:wid];
    }
}

- (void)updateWithWindowIds:(std::vector<CGWindowID>)windowIds {
    int old_count = capture_controllers.size();
    int count = windowIds.size();
    actual_count = count;

    for (int i = 0; i < count; i++) {
        if (i >= old_count) {
            [self appendViewControllerWithId:windowIds[i]];
        } else {
            [capture_controllers[i] updateWithWindowId:windowIds[i]];
        }

        CGFloat x = padding;
        CGFloat y = padding;
        x += (size.width + padding + innerPadding) * self.subviews.count;
        capture_controllers[i].view.frameOrigin = CGPointMake(x, y);
        [self addSubview:capture_controllers[i].view];
    }
}

- (void)appendViewControllerWithId:(CGWindowID)wid {
    CaptureViewController* captureViewController =
        [[CaptureViewController alloc] initWithWindowId:wid
                                                   size:size
                                           innerPadding:innerPadding
                                       titleTextPadding:titleTextPadding];
    capture_controllers.push_back(captureViewController);
}

- (void)startCaptureSubviews {
    for (CaptureViewController* controller : capture_controllers) {

        // hack to support GLCaptureView's unique shader preparation requirements
        if ([controller.captureView isKindOfClass:[GLCaptureView class]] &&
            ![[controller.captureView valueForKey:@"prepared"] boolValue])
            continue;

        // dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),
        //                ^{ [controller.captureView startCapture]; });
        // dispatch_async(dispatch_get_main_queue(), ^{ [controller.captureView startCapture]; });
        [controller.captureView startCapture];
    }
}

- (void)stopCaptureSubviews {
    for (CaptureViewController* controller : capture_controllers) {
        // dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),
        //                ^{ [controller.captureView stopCapture]; });
        // dispatch_async(dispatch_get_main_queue(), ^{ [controller.captureView stopCapture]; });
        [controller.captureView stopCapture];
    }
}

- (void)cycleSelectedIndex {
    if (actual_count == 0) return;

    [capture_controllers[selectedIndex] unhighlight];
    selectedIndex++;
    if (selectedIndex == actual_count) selectedIndex = 0;
    [capture_controllers[selectedIndex] highlight];
}

- (CGWindowID)getSelectedWindowId {
    if (actual_count == 0) return -1;

    return capture_controllers[selectedIndex].wid;
}

- (void)reset {
    self.subviews = [NSArray array];
    [capture_controllers[selectedIndex] unhighlight];
    selectedIndex = 0;
}

@end
