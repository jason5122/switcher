#import "model/window_element.h"
#import "view/CaptureView.h"
#import <Cocoa/Cocoa.h>

@interface CaptureViewController : NSViewController {
@public
    CaptureView* captureView;
}

- (instancetype)initWithWindow:(window_element)window_element;
- (instancetype)initWithWindowId:(CGWindowID)wid;
- (void)startCapture;
- (void)stopCapture;
- (void)highlight;
- (void)unhighlight;

@end
