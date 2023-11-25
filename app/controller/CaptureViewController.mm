#import "CaptureViewController.h"
#import "extensions/ScreenCaptureKit.h"

@implementation CaptureViewController

- (instancetype)initWithWindow:(window)window {
    self = [super init];
    if (self) {
        CGFloat width = 320, height = 200;
        NSRect captureRect = NSMakeRect(0, 0, width, height);

        NSVisualEffectView* blurView = [[NSVisualEffectView alloc] init];
        blurView.frame = captureRect;
        blurView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
        blurView.material = NSVisualEffectMaterialDark;
        blurView.state = NSVisualEffectStateActive;
        blurView.wantsLayer = true;
        blurView.layer.cornerRadius = 9.0;

        // NSStackView* stackView = [[NSStackView alloc] init];
        // // stackView.edgeInsets = {50, 50, 50, 50};
        // // stackView.frame = CGRectMake(0, 0, 100, 100);
        // stackView.wantsLayer = true;
        // stackView.layer.borderColor = CGColorGetConstantColor(kCGColorBlack);
        // stackView.layer.borderWidth = 5;
        // stackView.layer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);

        CGRect finalFrame = CGRectInset(captureRect, 50, 50);
        // CGRect finalFrame = captureRect;
        SCWindow* capture_window = [[SCWindow alloc] initWithId:window.wid];
        captureView = [[CaptureView alloc] initWithFrame:finalFrame targetWindow:capture_window];
        // [stackView addSubview:captureView];
        [blurView addSubview:captureView];

        // NSTextField* titleText = [NSTextField labelWithString:window.title];
        // titleText.frameOrigin = CGPointMake(x, y - 20);
        // titleText.frameSize = CGSizeMake(width, 20);
        // titleText.alignment = NSTextAlignmentCenter;
        // [blurView addSubview:titleText];

        // self.view = captureView;
        // self.view = stackView;
        self.view = blurView;
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
