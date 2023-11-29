#import "CaptureViewController.h"
#import "extensions/ScreenCaptureKit.h"

// TODO: maybe get rid of this and merge with CaptureView.mm?
@implementation CaptureViewController

- (instancetype)initWithWindow:(window)window {
    self = [super init];
    if (self) {
        self->w = window;

        CGFloat padding = 15;
        CGFloat width = 280, height = 175;
        CGRect viewFrame = NSMakeRect(0, 0, width + padding * 2, height + padding * 2);
        CGRect captureFrame = NSMakeRect(padding, padding, width, height);

        NSStackView* stackView = [[NSStackView alloc] initWithFrame:viewFrame];
        stackView.wantsLayer = true;
        stackView.layer.cornerRadius = 9.0;

        SCWindow* capture_window = [[SCWindow alloc] initWithId:window.wid];
        captureView = [[CaptureView alloc] initWithFrame:captureFrame targetWindow:capture_window];
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

- (void)focusWindow {
    w.focus();
}

@end
