#import "model/application.h"
#import "private_apis/CGSSpace.h"
#import "view/CaptureView.h"
#import <Cocoa/Cocoa.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>
#import <vector>

@interface WindowController : NSWindowController <NSWindowDelegate> {
    NSWindow* window;
    AXUIElementRef axUiElement;

@private
    CGSSpace* space;
    int selectedIndex;
    pid_t appPid;

    std::vector<application> applications;
    std::vector<CaptureView*> screen_captures;
    std::vector<AXUIElementRef> axui_refs;
}

@property(nonatomic) bool isShown;

- (void)cycleSelectedIndex;
- (void)focusSelectedIndex;
- (void)showWindow;
- (void)hideWindow;

@end
