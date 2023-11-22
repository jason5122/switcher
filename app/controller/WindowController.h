#import "private_apis/CGSSpace.h"
#import <Cocoa/Cocoa.h>

struct CppMembers;

@interface WindowController : NSWindowController <NSWindowDelegate> {
    struct CppMembers* _cppMembers;
    NSWindow* window;
    NSArray* filtered_windows;

@private
    CGSSpace* space;
}

- (void)setupWindowAndSpace;

@end
