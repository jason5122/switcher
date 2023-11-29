#import "controller/CaptureViewController.h"
#import "model/application.h"
#import "model/window.h"
#import "private_apis/CGSSpace.h"
#import "view/MainView.h"
#import <Cocoa/Cocoa.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>
#import <vector>

@interface WindowController : NSWindowController {
    NSWindow* mainWindow;
    MainView* mainView;
    AXUIElementRef axUiElement;

@private
    CGSSpace* space;
    int selectedIndex;

    std::vector<application> applications;
    std::vector<window> windows;
    std::vector<CaptureViewController*> capture_controllers;

    CaptureViewController* cvc1;
    CaptureView* cv1;

    std::vector<CGWindowID> cgWindowIds;
}

@property(nonatomic) bool isShown;

- (void)cycleSelectedIndex;
- (void)focusSelectedIndex;
- (void)showWindow;
- (void)hideWindow;

@end
