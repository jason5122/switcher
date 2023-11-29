#import "model/window.h"
#import "view/CaptureView.h"
#import <Cocoa/Cocoa.h>

@interface CaptureViewController : NSViewController {
    CaptureView* captureView;
    window w;  // TODO: better name and type?
}

- (instancetype)initWithWindow:(window)window;
- (void)startCapture;
- (void)stopCapture;
- (void)highlight;
- (void)unhighlight;
- (void)focusWindow;

@end
