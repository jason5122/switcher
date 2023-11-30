#import "MainView.h"
#import "model/spaces.h"
#import "view/CaptureView.h"

@implementation MainView

- (instancetype)initWithCaptureSize:(CGSize)theSize
                            padding:(CGFloat)thePadding
                       innerPadding:(CGFloat)theInnerPadding {
    self = [super init];
    if (self) {
        size = theSize;
        padding = thePadding;
        innerPadding = theInnerPadding;
        selectedIndex = 0;

        self.material = NSVisualEffectMaterialHUDWindow;
        self.state = NSVisualEffectStateActive;
        self.wantsLayer = true;
        self.layer.cornerRadius = 9.0;
    }
    return self;
}

- (void)ahaha {
    for (CGWindowID wid : [Space getAllWindowIds]) {
        CaptureViewController* captureViewController =
            [[CaptureViewController alloc] initWithWindowId:wid
                                                       size:size
                                               innerPadding:innerPadding];

        CGFloat x = padding;
        CGFloat y = padding;
        x += (size.width + padding + innerPadding) * self.subviews.count;
        captureViewController.view.frameOrigin = CGPointMake(x, y);

        [self addSubview:captureViewController.view];
        capture_controllers.push_back(captureViewController);
    }
}

- (void)addCaptureSubview:(window_element)window_element {
    CaptureViewController* captureViewController =
        [[CaptureViewController alloc] initWithWindow:window_element];

    CGFloat x = padding;
    CGFloat y = padding;
    x += (size.width + padding + innerPadding) * self.subviews.count;
    captureViewController.view.frameOrigin = CGPointMake(x, y);

    [self addSubview:captureViewController.view];
    capture_controllers.push_back(captureViewController);
}

- (void)startCaptureSubviews {
    for (CaptureViewController* controller : capture_controllers) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{ [controller startCapture]; });
    }
}

- (void)stopCaptureSubviews {
    for (CaptureViewController* controller : capture_controllers) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{ [controller stopCapture]; });
    }
}

- (void)cycleSelectedIndex {
    if (capture_controllers.empty()) return;

    [capture_controllers[selectedIndex] unhighlight];
    selectedIndex++;
    if (selectedIndex == capture_controllers.size()) selectedIndex = 0;
    [capture_controllers[selectedIndex] highlight];
}

- (void)focusSelectedIndex {
    if (capture_controllers.empty()) return;

    // [capture_controllers[selectedIndex] focusWindow];
}

@end
