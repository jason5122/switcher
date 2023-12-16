#import "TimerView.h"
#import "private_apis/CGS.h"
#import "util/log_util.h"

@implementation TimerView

- (instancetype)initWithFrame:(CGRect)frame windowId:(CGWindowID)theWid {
    self = [super initWithFrame:frame];
    if (self) {
        wid = theWid;

        self.wantsLayer = true;
        self.layer.contents = [NSImage imageWithSystemSymbolName:@"star.fill"
                                        accessibilityDescription:@"Status bar icon"];

        timer = [NSTimer scheduledTimerWithTimeInterval:1.0f / 60
                                                 target:self
                                               selector:@selector(setRandomColor)
                                               userInfo:nil
                                                repeats:true];
    }
    return self;
}

- (void)setRandomColor {
    // NSArray<NSColor*>* colors = @[ NSColor.redColor, NSColor.blueColor, NSColor.greenColor ];
    // NSUInteger randNum = arc4random() % [colors count];
    // self.layer.backgroundColor = [colors objectAtIndex:randNum].CGColor;

    bool captureAtNominalResolution = true;

    CGSWindowCaptureOptions options = kCGSCaptureIgnoreGlobalClipShape;
    if (captureAtNominalResolution) options |= kCGSWindowCaptureNominalResolution;

    CFArrayRef thumbnailList = CGSHWCaptureWindowList(CGSMainConnectionID(), &wid, 1, options);
    CGImageRef thumbnail = (CGImageRef)CFArrayGetValueAtIndex(thumbnailList, 0);
    self.layer.contents = (__bridge id)thumbnail;

    CFRelease(thumbnailList);
}

@end
