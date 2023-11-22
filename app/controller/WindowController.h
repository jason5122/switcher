#import "private_apis/CGSSpace.h"
#import <Cocoa/Cocoa.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>

struct CppMembers;

@interface WindowController : NSWindowController <NSWindowDelegate> {
    struct CppMembers* _cppMembers;
    NSWindow* window;

@private
    CGSSpace* space;
}

- (void)setupWindowAndSpace;

@end
