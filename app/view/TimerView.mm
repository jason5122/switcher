#import "TimerView.h"
#import "private_apis/CGS.h"
#import "util/log_util.h"

@implementation TimerView

- (instancetype)initWithFrame:(CGRect)frame windowId:(CGWindowID)theWid {
    self = [super initWithFrame:frame];
    if (self) {
        wid = theWid;
    }
    return self;
}

- (void)startCapture {
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0f / 60
                                             target:self
                                           selector:@selector(captureFrame)
                                           userInfo:nil
                                            repeats:true];
}

- (void)stopCapture {
    [timer invalidate];
    timer = nil;
}

- (void)updateWindowId:(CGWindowID)theWid {
    wid = theWid;
}

- (void)captureFrame {
    bool captureAtNominalResolution = true;

    CGSWindowCaptureOptions options = kCGSCaptureIgnoreGlobalClipShape;
    if (captureAtNominalResolution) options |= kCGSWindowCaptureNominalResolution;

    CFArrayRef thumbnailList = CGSHWCaptureWindowList(CGSMainConnectionID(), &wid, 1, options);
    if (thumbnailList) {
        CGImageRef frame = (CGImageRef)CFArrayGetValueAtIndex(thumbnailList, 0);
        CFRetain(frame);
        CFRelease(thumbnailList);

        // https://stackoverflow.com/a/39548167/14698275
        self.layer.minificationFilter = kCAFilterTrilinear;
        self.layer.contents = (__bridge id)frame;
        CFRelease(frame);
    }
}

@end
