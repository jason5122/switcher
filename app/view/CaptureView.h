#import <Cocoa/Cocoa.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>

enum { UNIFORM_MVP, UNIFORM_TEXTURE, NUM_UNIFORMS };
enum { ATTRIB_VERTEX, ATTRIB_TEXCOORD, NUM_ATTRIBS };

struct program_info_t {
    GLuint id;
    GLint uniform[NUM_UNIFORMS];
};

@interface CaptureView : NSOpenGLView {
    bool hasStarted;

@public
    program_info_t* program;
    GLuint quadVAOId, quadVBOId;
    bool quadInit;

    SCStream* disp;
    SCStreamConfiguration* streamConfig;
    IOSurfaceRef current, prev;
    pthread_mutex_t mutex;
}

- (id)initWithFrame:(NSRect)frame targetWindow:(SCWindow*)window;
- (void)startCapture;
- (void)stopCapture;
- (void)setupShaders;

@end
