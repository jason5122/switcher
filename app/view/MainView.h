#import "controller/CaptureViewController.h"
#import "model/window.h"
#import <Cocoa/Cocoa.h>
#import <vector>

@interface MainView : NSVisualEffectView {
    NSSize size;
    CGFloat padding;
    CGFloat innerPadding;

    // TODO: somehow extract this from self.subviews?
@public
    std::vector<CaptureViewController*> capture_controllers;

    // TODO: think about moving these to a controller (e.g., WindowController)
    int selectedIndex;
    std::vector<window> windows;
}

- (instancetype)initWithCaptureSize:(NSSize)size
                            padding:(CGFloat)padding
                       innerPadding:(CGFloat)innerPadding;

- (void)addCaptureSubview:(window)window;
- (void)addCaptureSubviewId:(CGWindowID)wid;
// - (void)removeCaptureSubview:(int)index;
- (void)startCaptureSubviews;
- (void)stopCaptureSubviews;
- (void)cycleSelectedIndex;
- (void)focusSelectedIndex;

@end
