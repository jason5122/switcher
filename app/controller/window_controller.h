#import "controller/view_controller.h"
#import <Cocoa/Cocoa.h>

@interface WindowController : NSWindowController <NSWindowDelegate>

- (instancetype)initWithBounds:(CGRect)bounds;
- (void)windowDidResize:(NSNotification*)notification;

@end