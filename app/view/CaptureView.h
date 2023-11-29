#import <Cocoa/Cocoa.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>

struct CppMembers;

@interface CaptureView : NSOpenGLView {
    struct CppMembers* cpp;
@public
    SCWindow* targetWindow;
    bool hasStarted;
}

- (id)initWithFrame:(NSRect)frame targetWindow:(SCWindow*)window;
- (void)startCapture;
- (void)stopCapture;

@end
