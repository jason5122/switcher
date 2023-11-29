#import "MainView.h"
#import "view/CaptureView.h"

@implementation MainView

- (instancetype)initWithCaptureSize:(NSSize)initialSize
                            padding:(CGFloat)initialPadding
                       innerPadding:(CGFloat)initialInnerPadding {
    self = [super init];
    if (self) {
        size = initialSize;
        padding = initialPadding;
        innerPadding = initialInnerPadding;

        self.material = NSVisualEffectMaterialHUDWindow;
        self.state = NSVisualEffectStateActive;
        self.wantsLayer = true;
        self.layer.cornerRadius = 9.0;
    }
    return self;
}

- (void)addCaptureSubview:(window)window {
    CaptureViewController* captureViewController =
        [[CaptureViewController alloc] initWithWindow:window];

    CGFloat x = padding;
    CGFloat y = padding;
    x += (size.width + padding) * self.subviews.count;
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

@end