#import <Cocoa/Cocoa.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>

struct screen_capture;
struct program_info_t;

@interface ScreenCaptureDelegate : NSObject <SCStreamOutput>
@property struct screen_capture* sc;
@end

class capture_engine {
public:
    capture_engine(NSOpenGLContext* context);
    bool start_capture(NSRect frame);
    void tick();
    void render();

private:
    ScreenCaptureDelegate* capture_delegate;

    screen_capture* sc;
    program_info_t* program;

    GLuint quadVAOId, quadVBOId;
    BOOL quadInit = NO;

    void setup_shaders();
    void init_quad(IOSurfaceRef surface);
};
