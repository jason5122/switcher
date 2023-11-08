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
    void screen_capture_video_render();

    void draw1();
    void draw2();
    void draw3();
    void setup1();
    void draw4(CGRect bounds);

private:
    GLuint texture;
    screen_capture* sc;
    Shader shader;

    GLuint quadVAOId, quadVBOId;
    BOOL quadInit = NO;
};
