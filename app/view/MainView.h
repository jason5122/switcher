#import "controller/CaptureViewController.h"
#import "model/window_element.h"
#import <Cocoa/Cocoa.h>
#import <vector>

@interface MainView : NSVisualEffectView {
    CGSize size;
    CGFloat padding;
    CGFloat innerPadding;
    int selectedIndex;
    std::vector<CaptureViewController*> capture_controllers;
}

- (instancetype)initWithCaptureSize:(CGSize)size
                            padding:(CGFloat)padding
                       innerPadding:(CGFloat)innerPadding;

- (void)populateWithCurrentWindows;
- (void)startCaptureSubviews;
- (void)stopCaptureSubviews;
- (void)cycleSelectedIndex;
- (void)focusSelectedIndex;
- (void)reset;

@end
