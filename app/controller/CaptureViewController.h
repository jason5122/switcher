#import "model/window_element.h"
#import "swift_capture_view.h"
#import "view/CaptureView.h"
#import "view/GLCaptureView.h"
#import "view/TimerView.h"
#import <Cocoa/Cocoa.h>

@interface CaptureViewController : NSViewController {
    CGSize size;
    NSTextField* titleText;
    NSImageView* iconView;
}

// @property(nonatomic) CaptureView* captureView;
// @property(nonatomic) SwiftCaptureView* captureView;
// @property(nonatomic) GLCaptureView* captureView;
// @property(nonatomic) id captureView;
@property(nonatomic) TimerView* captureView;
@property(nonatomic) CGWindowID wid;

- (instancetype)initWithWindowId:(CGWindowID)wid
                            size:(CGSize)theSize
                    innerPadding:(CGFloat)innerPadding
                titleTextPadding:(CGFloat)titleTextPadding;
- (void)updateWithWindowId:(CGWindowID)wid;
- (void)highlight;
- (void)unhighlight;

@end
