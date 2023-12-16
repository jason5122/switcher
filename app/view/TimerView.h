#import <Cocoa/Cocoa.h>

@interface TimerView : NSView {
    NSTimer* timer;
}

- (instancetype)initWithFrame:(CGRect)frame;
- (void)setRandomColor;

@end
