#import <Cocoa/Cocoa.h>

@interface TimerView : NSView {
    CGWindowID wid;
    NSTimer* timer;
}

- (instancetype)initWithFrame:(CGRect)frame windowId:(CGWindowID)wid;
- (void)startCapture;
- (void)stopCapture;
- (void)updateWindowId:(CGWindowID)theWid;

@end
