#import "CaptureViewController.h"
#import "extensions/ScreenCaptureKit.h"

@implementation CaptureViewController

- (instancetype)initWithWindow:(window)window {
    self = [super init];
    if (self) {
        // CGFloat width = 320, height = 200;
        // CGFloat padding = 20;
        CGFloat padding = 10;
        CGFloat width = 320 - padding * 3.2, height = 200 - padding * 2;
        // NSRect captureRect = NSMakeRect(0, 0, width, height);
        NSRect captureRect = NSMakeRect(0, 0, width + padding * 3.2, height + padding * 2);

        // NSVisualEffectView* blurView = [[NSVisualEffectView alloc] initWithFrame:captureRect];
        // // blurView.frame = captureRect;
        // blurView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
        // blurView.material = NSVisualEffectMaterialSelection;
        // blurView.state = NSVisualEffectStateActive;
        // blurView.wantsLayer = true;
        // blurView.layer.cornerRadius = 9.0;

        NSStackView* stackView = [[NSStackView alloc] initWithFrame:captureRect];
        // stackView.edgeInsets = {50, 50, 50, 50};
        // stackView.frame = CGRectMake(0, 0, 100, 100);
        stackView.wantsLayer = true;
        stackView.layer.backgroundColor =
            [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.1f].CGColor;
        stackView.layer.cornerRadius = 9.0;
        // stackView.layer.borderColor = CGColorGetConstantColor(kCGColorBlack);
        // stackView.layer.borderWidth = 5;
        // stackView.layer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);

        // CGRect finalFrame = CGRectInset(captureRect, 10, 10);
        // CGRect finalFrame = captureRect;
        CGRect finalFrame = NSMakeRect(padding * 1.6, padding, width, height);
        SCWindow* capture_window = [[SCWindow alloc] initWithId:window.wid];
        captureView = [[CaptureView alloc] initWithFrame:finalFrame targetWindow:capture_window];
        [stackView addSubview:captureView];
        // [blurView addSubview:captureView];

        // NSTextField* titleText = [NSTextField labelWithString:window.title];
        // titleText.frameOrigin = CGPointMake(0, 0);
        // titleText.frameSize = CGSizeMake(width, 20);
        // titleText.alignment = NSTextAlignmentCenter;
        // [stackView addSubview:titleText];

        // self.view = captureView;
        self.view = stackView;
        // self.view = blurView;
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
