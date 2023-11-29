#import "controller/CaptureViewController.h"
#import "model/application.h"
#import "private_apis/CGSSpace.h"
#import "view/MainView.h"
#import <Cocoa/Cocoa.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>
#import <vector>

@interface WindowController : NSWindowController {
    CGSize size;
    CGFloat padding;
    CGFloat innerPadding;
    MainView* mainView;
    AXUIElementRef axUiElement;
    CGSSpace* space;
    int selectedIndex;

    std::vector<application> applications;
}

@property(nonatomic, getter=isShown) bool shown;

- (instancetype)initWithSize:(CGSize)size
                     padding:(CGFloat)padding
                innerPadding:(CGFloat)innerPadding;
- (void)cycleSelectedIndex;
- (void)focusSelectedIndex;
- (void)showWindow;
- (void)hideWindow;

@end
