#import "CaptureViewController.h"
#import "extensions/ScreenCaptureKit.h"

@implementation CaptureViewController

- (instancetype)initWithWindowId:(CGWindowID)windowId {
    self = [super init];
    if (self) {
        CGFloat width = 320, height = 200;
        NSRect captureRect = NSMakeRect(0, 0, width, height);

        NSVisualEffectView* visualEffect = [[NSVisualEffectView alloc] init];
        visualEffect.blendingMode = NSVisualEffectBlendingModeBehindWindow;
        visualEffect.material = NSVisualEffectMaterialHUDWindow;
        visualEffect.state = NSVisualEffectStateActive;

        visualEffect.wantsLayer = true;
        visualEffect.layer.cornerRadius = 9.0;

        SCWindow* capture_window = [[SCWindow alloc] initWithId:windowId];

        captureView = [[CaptureView alloc] initWithFrame:captureRect targetWindow:capture_window];
        self.view = captureView;
    }
    return self;
}

- (void)startCapture {
    [captureView startCapture];
}

- (void)stopCapture {
    [captureView stopCapture];
}

@end
