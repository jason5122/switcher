#import "model/window.h"
#import "view/CaptureView.h"
#import <Cocoa/Cocoa.h>

@interface CaptureViewController : NSViewController {
    CaptureView* captureView;
}

- (instancetype)initWithWindow:(window)window;
- (void)startCapture;
- (void)stopCapture;
- (void)highlight;
- (void)unhighlight;

@end
