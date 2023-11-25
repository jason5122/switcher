#import "model/application.h"
#import "model/window.h"
#import "private_apis/CGSSpace.h"
#import "view/CaptureView.h"
#import <Cocoa/Cocoa.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>
#import <vector>

@interface WindowController : NSWindowController <NSWindowDelegate> {
    NSWindow* nswindow;
    AXUIElementRef axUiElement;

@private
    CGSSpace* space;
    int selectedIndex;

    std::vector<application> applications;
    std::vector<window> windows;
    std::vector<CaptureView*> screen_captures;
}

@property(nonatomic) bool isShown;

- (void)cycleSelectedIndex;
- (void)focusSelectedIndex;
- (void)showWindow;
- (void)hideWindow;

@end
