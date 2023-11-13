#import "model/capture_engine.h"
#import "util/log_util.h"
#import "view/opengl_view.h"
#import <Cocoa/Cocoa.h>
#import <OpenGL/gl3.h>

struct CppMembers {
    CaptureEngine* capture_engine;
};

@implementation OpenGLView

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
        log_with_type(OS_LOG_TYPE_ERROR, @"failed to create pixel format", @"opengl-view");
        return nil;
    }

    self = [super initWithFrame:frame pixelFormat:pf];
    if (self) {
        _cppMembers = new CppMembers;
    }
    return self;
}

- (void)prepareOpenGL {
    [super prepareOpenGL];

    [self.openGLContext makeCurrentContext];
    glEnable(GL_MULTISAMPLE);

    _cppMembers->capture_engine = new CaptureEngine(self.openGLContext);

    if (!_cppMembers->capture_engine->start_capture()) {
        log_with_type(OS_LOG_TYPE_ERROR, @"start capture failed", @"opengl-view");
    }
}

- (void)update {
    [super update];
    [self.openGLContext update];
}

@end
