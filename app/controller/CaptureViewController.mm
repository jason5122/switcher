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
        // titleText.font = [NSFont systemFontOfSize:15];
        titleText.cell.lineBreakMode = NSLineBreakByTruncatingTail;
        [stackView addSubview:titleText];

        CGSConnectionID elementConnection;
        CGSGetWindowOwner(_CGSDefaultConnection(), wid, &elementConnection);
        ProcessSerialNumber psn = ProcessSerialNumber();
        CGSGetConnectionPSN(elementConnection, &psn);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        FSRef fsRef;
        GetProcessBundleLocation(&psn, &fsRef);
        IconRef iconRef;
        GetIconRefFromFileInfo(&fsRef, 0, NULL, 0, NULL, kIconServicesNormalUsageFlag, &iconRef,
                               NULL);
        NSImage* icon = [[NSImage alloc] initWithIconRef:iconRef];
#pragma clang diagnostic pop

        CGFloat sideLength = 44;
        NSImageView* iconView = [NSImageView imageViewWithImage:icon];
        iconView.image.size = NSMakeSize(sideLength, sideLength);
        iconView.frame = NSMakeRect(size.width - (sideLength - 4), -4, sideLength, sideLength);
        [captureView addSubview:iconView];

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
        [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.1f].CGColor;
}

- (void)unhighlight {
    self.view.layer.backgroundColor = CGColorGetConstantColor(kCGColorClear);
}

@end
