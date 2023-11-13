#import <Cocoa/Cocoa.h>

struct screen_capture;

enum { UNIFORM_MVP, UNIFORM_TEXTURE, NUM_UNIFORMS };

enum { ATTRIB_VERTEX, ATTRIB_TEXCOORD, NUM_ATTRIBS };

struct program_info_t {
    GLuint id;
    GLint uniform[NUM_UNIFORMS];
};

class CaptureEngine {
public:
    CaptureEngine(NSOpenGLContext* context);
    void screen_capture_video_tick();
    void screen_capture_video_render();
    void setup();

private:
    screen_capture* sc;

    program_info_t program;

    GLuint quadVAOId, quadVBOId;
    BOOL quadInit = NO;

    void setup_shaders();
    void init_quad(IOSurfaceRef surface);
};
