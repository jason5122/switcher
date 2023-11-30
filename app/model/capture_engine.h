#import "view/CaptureView.h"
#import <Cocoa/Cocoa.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>

struct screen_capture;
struct program_info_t;

@interface ScreenCaptureDelegate : NSObject <SCStreamOutput> {
    CaptureView* captureView;
    screen_capture* sc;
}

- (instancetype)init:(CaptureView*)captureView screenCapture:(screen_capture*)sc;

@end

class capture_engine {
public:
    capture_engine(NSOpenGLContext* context, NSRect frame, SCWindow* target_window,
                   CaptureView* captureView);
    bool start_capture();
    bool stop_capture();
    void tick();
    void render();

private:
    CaptureView* captureView;
    ScreenCaptureDelegate* capture_delegate;

    screen_capture* sc;
    program_info_t* program;

    GLuint quadVAOId, quadVBOId;
    BOOL quadInit = NO;

    void setup_shaders();
    void init_quad(IOSurfaceRef surface);
};
