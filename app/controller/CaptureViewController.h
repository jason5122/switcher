#import "model/window_element.h"
#import "swift_capture_view.h"
#import <Cocoa/Cocoa.h>

@interface CaptureViewController : NSViewController {
    CGSize size;
    NSTextField* titleText;
    NSImageView* iconView;
}

@property(nonatomic) SwiftCaptureView* captureView;
@property(nonatomic) CGWindowID wid;

- (instancetype)initWithWindowId:(CGWindowID)wid
                            size:(CGSize)theSize
                    innerPadding:(CGFloat)innerPadding
                titleTextPadding:(CGFloat)titleTextPadding;
- (void)updateWithWindowId:(CGWindowID)wid;
- (void)highlight;
- (void)unhighlight;

@end
