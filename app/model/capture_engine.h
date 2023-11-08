#import "model/shader.h"
#import <Cocoa/Cocoa.h>

struct screen_capture;

class CaptureEngine {
public:
    CaptureEngine(NSOpenGLContext* context, GLuint texture);
    void screen_capture_video_tick();
    void screen_capture_video_render(CGRect bounds);

    void setup();
    void setup_shaders();

private:
    screen_capture* sc;

    GLuint quadVAOId, quadVBOId;
    BOOL quadInit = NO;
    Shader proggy;
};
