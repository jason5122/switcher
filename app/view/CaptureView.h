#import <Cocoa/Cocoa.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>

@interface CaptureView : NSOpenGLView {
@public
    SCWindow* targetWindow;
    bool hasStarted;

@public
    SCStream* disp;
    SCStreamConfiguration* streamConfig;
    IOSurfaceRef current, prev;
    pthread_mutex_t mutex;
}

- (id)initWithFrame:(NSRect)frame targetWindow:(SCWindow*)window;
- (void)startCapture;
- (void)stopCapture;

@end
