#import "private_apis/CGSSpace.h"
#import <Cocoa/Cocoa.h>

@interface WindowController : NSWindowController <NSWindowDelegate> {
    NSWindow* window;

@private
    CGSSpace* space;
}

- (void)setupWindowAndSpace;

@end
