#import "CaptureView.h"
#import "model/capture_engine.h"
#import "util/log_util.h"
#import <Cocoa/Cocoa.h>
#import <OpenGL/gl3.h>

struct CppMembers {
    capture_engine* capture_engine;
};

@implementation CaptureView

- (id)initWithFrame:(NSRect)frame targetWindow:(SCWindow*)window {
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
        log_with_type(OS_LOG_TYPE_ERROR, @"failed to create pixel format", @"capture-view");
        return nil;
    }

    self = [super initWithFrame:frame pixelFormat:pf];
    if (self) {
        cpp = new CppMembers;
        targetWindow = window;
        hasStarted = false;
    }
    return self;
}

- (void)prepareOpenGL {
    [super prepareOpenGL];

    [self.openGLContext makeCurrentContext];
    glEnable(GL_MULTISAMPLE);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    GLint opacity = 0;
    [self.openGLContext setValues:&opacity forParameter:NSOpenGLCPSurfaceOpacity];
#pragma clang diagnostic pop

    cpp->capture_engine = new capture_engine(self.openGLContext, self.frame, targetWindow);
}

- (void)startCapture {
    if (hasStarted) return;

    log_with_type(OS_LOG_TYPE_DEFAULT, @"hey there", @"capture-view");

    if (!cpp->capture_engine->start_capture()) {
        log_with_type(OS_LOG_TYPE_ERROR, @"start capture failed", @"capture-view");
    } else {
        hasStarted = true;
    }
}

- (void)stopCapture {
    if (!hasStarted) return;

    if (!cpp->capture_engine->stop_capture()) {
        log_with_type(OS_LOG_TYPE_ERROR, @"stop capture failed", @"capture-view");
    } else {
        hasStarted = false;
    }
}

- (void)update {
    [super update];
    [self.openGLContext update];
}

@end
