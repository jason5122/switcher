#import <Cocoa/Cocoa.h>

struct screen_capture;
struct program_info_t;

class CaptureEngine {
public:
    CaptureEngine(NSOpenGLContext* context);
    void screen_capture_video_tick();
    void screen_capture_video_render();

private:
    screen_capture* sc;
    program_info_t* program;

    GLuint quadVAOId, quadVBOId;
    BOOL quadInit = NO;

    void setup_shaders();
    void init_quad(IOSurfaceRef surface);
};
