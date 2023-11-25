#import "view/CaptureView.h"
#import <Cocoa/Cocoa.h>

@interface CaptureViewController : NSViewController {
    CaptureView* captureView;
}

- (instancetype)initWithWindowId:(CGWindowID)windowId;
- (void)startCapture;
- (void)stopCapture;

@end
