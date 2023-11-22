#import <Cocoa/Cocoa.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>

struct CppMembers;

@interface OpenGLView : NSOpenGLView {
    struct CppMembers* _cppMembers;
    SCWindow* targetWindow;
    bool hasStarted;
}

- (id)initWithFrame:(NSRect)frame targetWindow:(SCWindow*)window;
- (void)startCapture;

@end
