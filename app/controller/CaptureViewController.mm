#import "CaptureViewController.h"
#import "extensions/CGWindow.h"
#import "extensions/NSImage+InitWithId.h"
#import "extensions/ScreenCaptureKit+InitWithId.h"
#import "util/log_util.h"

@implementation CaptureViewController

- (instancetype)initWithWindowId:(CGWindowID)wid
                            size:(CGSize)theSize
                    innerPadding:(CGFloat)innerPadding
                titleTextPadding:(CGFloat)titleTextPadding {
    self = [super init];
    if (self) {
        size = theSize;

        CGRect viewFrame = NSMakeRect(0, 0, size.width + innerPadding * 2,
                                      size.height + innerPadding * 2 + titleTextPadding);
        CGRect captureFrame =
            NSMakeRect(innerPadding, innerPadding + titleTextPadding, size.width, size.height);

        NSStackView* stackView = [[NSStackView alloc] initWithFrame:viewFrame];
        stackView.wantsLayer = true;
        stackView.layer.cornerRadius = 9.0;

        SCStreamConfiguration* config = [[SCStreamConfiguration alloc] init];
        config.width = captureFrame.size.width * 2;
        config.height = captureFrame.size.height * 2;
        config.queueDepth = 8;
        config.showsCursor = false;
        config.pixelFormat = 'BGRA';
        config.colorSpaceName = kCGColorSpaceDisplayP3;

        // TODO: Make this work with CaptureView.
        // _captureView = [[CaptureView alloc] initWithFrame:captureFrame configuration:config];
        // _captureView = [[SwiftCaptureView alloc] initWithFrame:captureFrame
        // configuration:config]; _captureView = [[GLCaptureView alloc] initWithFrame:captureFrame
        // configuration:config];
        _captureView = [[TimerView alloc] initWithFrame:captureFrame windowId:wid];
        [stackView addSubview:_captureView];

        titleText = [NSTextField labelWithString:@""];
        titleText.frameOrigin = CGPointMake(innerPadding, 5);
        titleText.frameSize = CGSizeMake(size.width, 20);
        titleText.alignment = NSTextAlignmentCenter;
        titleText.cell.lineBreakMode = NSLineBreakByTruncatingTail;
        [stackView addSubview:titleText];

        iconView = [[NSImageView alloc] init];
        [_captureView addSubview:iconView];

        [self updateWithWindowId:wid];

        self.view = stackView;
    }
    return self;
}

- (void)updateWithWindowId:(CGWindowID)wid {
    _wid = wid;

    // SCWindow* targetWindow = [[SCWindow alloc] initWithId:wid];
    // SCContentFilter* filter =
    //     [[SCContentFilter alloc] initWithDesktopIndependentWindow:targetWindow];
    // [_captureView updateWithFilter:filter];
    [_captureView updateWindowId:wid];

    titleText.stringValue = CGWindowGetTitle(wid);

    NSImage* icon = [[NSImage alloc] initWithId:wid];
    iconView.frameSize = icon.size;
    iconView.frameOrigin = NSMakePoint(size.width - icon.size.width, 0);
    iconView.image = icon;
}

- (void)highlight {
    self.view.layer.backgroundColor =
        [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.1f].CGColor;
}

- (void)unhighlight {
    self.view.layer.backgroundColor = CGColorGetConstantColor(kCGColorClear);
}

@end
