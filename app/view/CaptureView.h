#import <Cocoa/Cocoa.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>

@interface CaptureView : NSOpenGLView {
    bool hasStarted;
}

- (id)initWithFrame:(NSRect)frame targetWindow:(SCWindow*)window;
- (void)startCapture;
- (void)stopCapture;

@end
