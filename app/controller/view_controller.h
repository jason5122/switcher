#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController {
    NSRect contentSize;
}

- (instancetype)initWithBounds:(CGRect)bounds;
- (void)resizeView;

@end
