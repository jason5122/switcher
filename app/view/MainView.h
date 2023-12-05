#import "controller/CaptureViewController.h"
#import "model/window_element.h"
#import <Cocoa/Cocoa.h>
#import <vector>

@interface MainView : NSVisualEffectView {
    CGSize size;
    CGFloat padding;
    CGFloat innerPadding;
    CGFloat titleTextPadding;
    int selectedIndex;
    std::vector<CaptureViewController*> capture_controllers;
}

- (instancetype)initWithCaptureSize:(CGSize)size
                            padding:(CGFloat)padding
                       innerPadding:(CGFloat)innerPadding
                   titleTextPadding:(CGFloat)titleTextPadding;
- (void)populateWithCount:(int)count;
- (void)updateWithWindowIds:(std::vector<CGWindowID>)windowIds;
- (void)startCaptureSubviews;
- (void)stopCaptureSubviews;
- (void)cycleSelectedIndex;
- (CGWindowID)getSelectedWindowId;
- (void)reset;

@end
