#import "CaptureViewController.h"
#import "private_apis/CGS.h"

// TODO: maybe get rid of this and merge with CaptureView.mm?
@implementation CaptureViewController

- (instancetype)initWithWindowId:(CGWindowID)wid
                            size:(CGSize)size
                    innerPadding:(CGFloat)innerPadding
                titleTextPadding:(CGFloat)titleTextPadding {
    self = [super init];
    if (self) {
        CGRect viewFrame = NSMakeRect(0, 0, size.width + innerPadding * 2,
                                      size.height + innerPadding * 2 + titleTextPadding);
        CGRect captureFrame =
            NSMakeRect(innerPadding, innerPadding + titleTextPadding, size.width, size.height);

        NSStackView* stackView = [[NSStackView alloc] initWithFrame:viewFrame];
        stackView.wantsLayer = true;
        stackView.layer.cornerRadius = 9.0;

        captureView = [[CaptureView alloc] initWithFrame:captureFrame windowId:wid];
        [stackView addSubview:captureView];

        CFStringRef title;
        CGSCopyWindowProperty(_CGSDefaultConnection(), wid, CFSTR("kCGSWindowTitle"), &title);
        NSTextField* titleText = [NSTextField labelWithString:(__bridge NSString*)title];
        titleText.frameOrigin = CGPointMake(innerPadding, 5);
        titleText.frameSize = CGSizeMake(size.width, 20);
        titleText.alignment = NSTextAlignmentCenter;
        titleText.font = [NSFont systemFontOfSize:15];
        [stackView addSubview:titleText];

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
