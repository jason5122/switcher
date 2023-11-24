#import "private_apis/CGSSpace.h"
#import <Cocoa/Cocoa.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>

struct CppMembers;

@interface WindowController : NSWindowController <NSWindowDelegate> {
    struct CppMembers* cpp;
    NSWindow* window;
    AXUIElementRef axUiElement;

@private
    CGSSpace* space;
    int selectedIndex;
    pid_t appPid;
}

@property(nonatomic) bool isShown;

- (void)focusSelectedIndex;
- (void)showWindow;
- (void)hideWindow;

@end
