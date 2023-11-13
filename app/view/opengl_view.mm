#import "model/capture_engine.h"
#import "util/log_util.h"
#import "view/opengl_view.h"
#import <Cocoa/Cocoa.h>
#import <OpenGL/gl3.h>

struct CppMembers {
    CaptureEngine* capture_engine;
};

@implementation OpenGLView

- (CVReturn)getFrameForTime:(const CVTimeStamp*)outputTime {
    @autoreleasepool {
        [self drawView];
    }
    return kCVReturnSuccess;
}

static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now,
                                      const CVTimeStamp* outputTime, CVOptionFlags flagsIn,
                                      CVOptionFlags* flagsOut, void* displayLinkContext) {
    CVReturn result = [(__bridge OpenGLView*)displayLinkContext getFrameForTime:outputTime];
    return result;
}

- (id)initWithFrame:(NSRect)frame {
    NSOpenGLPixelFormatAttribute attribs[] = {
        NSOpenGLPFAAllowOfflineRenderers,
        NSOpenGLPFAAccelerated,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAColorSize,
        32,
        NSOpenGLPFADepthSize,
        24,
        NSOpenGLPFAMultisample,
        1,
        NSOpenGLPFASampleBuffers,
        1,
        NSOpenGLPFASamples,
        4,
        NSOpenGLPFANoRecovery,
        NSOpenGLPFAOpenGLProfile,
        NSOpenGLProfileVersion3_2Core,
        0,
    };

    NSOpenGLPixelFormat* pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
    if (!pf) {
        log_with_type(OS_LOG_TYPE_ERROR, @"failed to create pixel format", @"capture-engine");
        return nil;
    }

    self = [super initWithFrame:frame pixelFormat:pf];
    if (self) {
        _cppMembers = new CppMembers;
    }
    return self;
}

- (void)initGL {
    [self.openGLContext makeCurrentContext];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    GLint one = 1;  // Synchronize buffer swaps with vertical refresh rate
    [self.openGLContext setValues:&one forParameter:NSOpenGLCPSwapInterval];
#pragma clang diagnostic pop

    glEnable(GL_MULTISAMPLE);
}

- (void)setupDisplayLink {
    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
    CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, (__bridge void*)self);

    CGLContextObj cglContext = self.openGLContext.CGLContextObj;
    CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);

    CVDisplayLinkStart(displayLink);
}

- (void)prepareOpenGL {
    [super prepareOpenGL];
    [self initGL];
    // [self setupDisplayLink];

    _cppMembers->capture_engine = new CaptureEngine(self.openGLContext);
    _cppMembers->capture_engine->setup();

    // [self drawView];  // initial draw call
}

- (void)update {
    [super update];
    [self.openGLContext update];
}

- (void)drawView {
    [self.openGLContext makeCurrentContext];
    CGLLockContext(self.openGLContext.CGLContextObj);

    _cppMembers->capture_engine->screen_capture_video_tick();
    _cppMembers->capture_engine->screen_capture_video_render();

    [self.openGLContext flushBuffer];

    CGLUnlockContext(self.openGLContext.CGLContextObj);
}

- (void)dealloc {
    CVDisplayLinkStop(displayLink);
    CVDisplayLinkRelease(displayLink);
}

@end
