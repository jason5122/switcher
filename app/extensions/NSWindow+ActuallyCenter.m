#import "NSWindow+ActuallyCenter.h"

@implementation NSWindow (ActuallyCenter)

- (void)actuallyCenter {
    NSSize screenSize = NSScreen.mainScreen.frame.size;
    NSSize panelSize = self.frame.size;
    CGFloat x = fmax(screenSize.width - panelSize.width, 0) * 0.5;
    CGFloat y = fmax(screenSize.height - panelSize.height, 0) * 0.5;
    self.frameOrigin = NSMakePoint(x, y);
}

@end
