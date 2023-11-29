#import "CaptureViewController.h"
#import "extensions/ScreenCaptureKit.h"

@implementation CaptureViewController

- (instancetype)initWithWindow:(window)window {
    self = [super init];
    if (self) {
        CGFloat padding = 15;
        CGFloat width = 280, height = 175;

        NSStackView* stackView = [[NSStackView alloc] init];
        stackView.wantsLayer = true;
        stackView.layer.cornerRadius = 9.0;

        // CGRect finalFrame = CGRectInset(captureRect, 10, 10);
        CGRect finalFrame = NSMakeRect(padding, padding, width, height);
        SCWindow* capture_window = [[SCWindow alloc] initWithId:window.wid];
        captureView = [[CaptureView alloc] initWithFrame:finalFrame targetWindow:capture_window];
        [stackView addSubview:captureView];

        NSImageView* iconView = [NSImageView imageViewWithImage:window.icon];
        iconView.image.size = NSMakeSize(48, 48);
        iconView.frame = NSMakeRect(width - 48, 0, 48, 48);
        iconView.wantsLayer = true;
        // iconView.layer.backgroundColor = NSColor.redColor.CGColor;
        [captureView addSubview:iconView];

        // NSTextField* titleText = [NSTextField labelWithString:window.title];
        // titleText.frameOrigin = CGPointMake(0, 0);
        // titleText.frameSize = CGSizeMake(width, 20);
        // titleText.alignment = NSTextAlignmentCenter;
        // [stackView addSubview:titleText];

        NSRect captureRect = NSMakeRect(0, 0, width + padding * 2, height + padding * 2);
        stackView.frame = captureRect;

        self.view = stackView;
    }
    return self;
}

- (void)startCapture {
    [captureView startCapture];
}

- (void)stopCapture {
    [captureView stopCapture];
}

- (void)highlight {
    self.view.layer.backgroundColor =
        [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.15f].CGColor;
}

- (void)unhighlight {
    self.view.layer.backgroundColor = CGColorGetConstantColor(kCGColorClear);
}

@end
