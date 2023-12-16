#import "TimerView.h"
#import "util/log_util.h"

@implementation TimerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.wantsLayer = true;
        self.layer.contents = [NSImage imageWithSystemSymbolName:@"star.fill"
                                        accessibilityDescription:@"Status bar icon"];
        [self setRandomColor];

        timer = [NSTimer scheduledTimerWithTimeInterval:1.0f / 60
                                                 target:self
                                               selector:@selector(setRandomColor)
                                               userInfo:nil
                                                repeats:true];
    }
    return self;
}

- (void)setRandomColor {
    NSArray<NSColor*>* colors = @[ NSColor.redColor, NSColor.blueColor, NSColor.greenColor ];
    NSUInteger randNum = arc4random() % [colors count];
    self.layer.backgroundColor = [colors objectAtIndex:randNum].CGColor;
}

@end
