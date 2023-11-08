#import "gl_cocoa.h"
#import "model/shader.h"
#import <Cocoa/Cocoa.h>

#define TEXTURE_WIDTH 1024
#define TEXTURE_HEIGHT 768

struct screen_capture;

class CaptureEngine {
public:
    CaptureEngine(NSOpenGLContext* context, GLuint texture);
    void screen_capture_video_tick();
    void screen_capture_video_render(CGRect bounds);

    void setup_shaders();

private:
    GLuint texture;
    screen_capture* sc;
    Shader shader;

    GLuint quadVAOId, quadVBOId;
    BOOL quadInit = NO;
};
