#import <Cocoa/Cocoa.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>

struct CppMembers;

@interface CaptureView : NSOpenGLView {
    struct CppMembers* cpp;
    SCWindow* targetWindow;
    bool hasStarted;
}

- (id)initWithFrame:(NSRect)frame targetWindow:(SCWindow*)window;
- (void)startCapture;

@end
