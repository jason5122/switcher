#import "model/window_element.h"
#import "view/CaptureView.h"
#import <Cocoa/Cocoa.h>

@interface CaptureViewController : NSViewController {
@public
    CaptureView* captureView;
}

- (instancetype)initWithWindowId:(CGWindowID)wid
                            size:(CGSize)size
                    innerPadding:(CGFloat)innerPadding
                titleTextPadding:(CGFloat)theTitleTextPadding;
- (void)startCapture;
- (void)stopCapture;
- (void)highlight;
- (void)unhighlight;

@end
