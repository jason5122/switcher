#import "controller/CaptureViewController.h"
#import "model/window.h"
#import <Cocoa/Cocoa.h>
#import <vector>

@interface MainView : NSVisualEffectView {
    NSSize size;
    CGFloat padding;
    CGFloat innerPadding;
    std::vector<CaptureViewController*> capture_controllers;
}

- (instancetype)initWithCaptureSize:(NSSize)size
                            padding:(CGFloat)padding
                       innerPadding:(CGFloat)innerPadding;

- (void)addCaptureSubview:(window)window;
- (void)startCaptureSubviews;
- (void)stopCaptureSubviews;

@end
