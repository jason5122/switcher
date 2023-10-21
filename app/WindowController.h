#include "ViewController.h"
#include <Cocoa/Cocoa.h>

@interface WindowController : NSWindowController <NSWindowDelegate>

- (instancetype)initWithBounds:(CGRect)bounds;
- (void)windowDidResize:(NSNotification*)notification;

@end
