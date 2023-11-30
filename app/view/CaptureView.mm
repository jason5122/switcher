#import "CaptureView.h"
#import "extensions/ScreenCaptureKit+InitWithId.h"
#import "util/file_util.h"
#import "util/log_util.h"
#import "util/shader_util.h"
#import <Cocoa/Cocoa.h>
#import <GLKit/GLKit.h>
#import <OpenGL/gl3.h>
#import <pthread.h>

enum { UNIFORM_MVP, UNIFORM_TEXTURE, NUM_UNIFORMS };
enum { ATTRIB_VERTEX, ATTRIB_TEXCOORD, NUM_ATTRIBS };

struct program_info_t {
    GLuint id;
    GLint uniform[NUM_UNIFORMS];
};

@interface ScreenCaptureDelegate : NSObject <SCStreamOutput> {
    CaptureView* captureView;
}

- (instancetype)initWithCaptureView:(CaptureView*)captureView;

@end

// http://philjordan.eu/article/mixing-objective-c-c++-and-objective-c++
@interface CaptureView () {
    ScreenCaptureDelegate* captureDelegate;
    SCStream* disp;
    SCStreamConfiguration* streamConfig;

    program_info_t* program;
    GLuint quadVAOId, quadVBOId;
    bool quadInit;

@public
    IOSurfaceRef current, prev;
    pthread_mutex_t mutex;
}
@end

@implementation CaptureView

- (id)initWithFrame:(NSRect)frame windowId:(CGWindowID)wid {
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
        custom_log(OS_LOG_TYPE_ERROR, @"capture-view", @"failed to create pixel format");
        return nil;
    }

    self = [super initWithFrame:frame pixelFormat:pf];
    if (self) {
        hasStarted = false;
        quadInit = false;

        program = new program_info_t();

        streamConfig = [[SCStreamConfiguration alloc] init];
        streamConfig.width = frame.size.width * 2;
        streamConfig.height = frame.size.height * 2;
        streamConfig.queueDepth = 8;
        streamConfig.showsCursor = false;
        streamConfig.pixelFormat = 'BGRA';
        streamConfig.colorSpaceName = kCGColorSpaceDisplayP3;

        SCWindow* targetWindow = [[SCWindow alloc] initWithId:wid];
        SCContentFilter* contentFilter =
            [[SCContentFilter alloc] initWithDesktopIndependentWindow:targetWindow];
        disp = [[SCStream alloc] initWithFilter:contentFilter
                                  configuration:streamConfig
                                       delegate:nil];

        pthread_mutex_init(&mutex, NULL);

        captureDelegate = [[ScreenCaptureDelegate alloc] initWithCaptureView:self];

        NSError* error = nil;
        BOOL did_add_output = [disp addStreamOutput:captureDelegate
                                               type:SCStreamOutputTypeScreen
                                 sampleHandlerQueue:nil
                                              error:&error];
        if (!did_add_output) {
            custom_log(OS_LOG_TYPE_ERROR, @"capture-engine", error.localizedFailureReason);
        }
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

    [self setupShaders];
}

- (void)startCapture {
    if (hasStarted) return;

    dispatch_semaphore_t stream_start_completed = dispatch_semaphore_create(0);

    __block BOOL success = false;
    [disp startCaptureWithCompletionHandler:^(NSError* _Nullable error) {
      success = (BOOL)(error == nil);
      if (!success) {
          custom_log(OS_LOG_TYPE_ERROR, @"capture-view", error.localizedFailureReason);
      }
      dispatch_semaphore_signal(stream_start_completed);
    }];
    dispatch_semaphore_wait(stream_start_completed, DISPATCH_TIME_FOREVER);

    if (!success) {
        custom_log(OS_LOG_TYPE_ERROR, @"capture-view", @"start capture failed");
    } else {
        hasStarted = true;
    }
}

- (void)stopCapture {
    if (!hasStarted) return;

    dispatch_semaphore_t stream_stop_completed = dispatch_semaphore_create(0);

    __block BOOL success = false;
    [disp stopCaptureWithCompletionHandler:^(NSError* _Nullable error) {
      success = (BOOL)(error == nil);
      if (!success) {
          custom_log(OS_LOG_TYPE_ERROR, @"capture-view", error.localizedFailureReason);
      }
      dispatch_semaphore_signal(stream_stop_completed);
    }];
    dispatch_semaphore_wait(stream_stop_completed, DISPATCH_TIME_FOREVER);

    if (!success) {
        custom_log(OS_LOG_TYPE_ERROR, @"capture-view", @"stop capture failed");
    } else {
        hasStarted = false;
    }
}

- (void)update {
    [super update];
    [self.openGLContext update];
}

- (void)setupShaders {
    glGenVertexArrays(1, &quadVAOId);
    glGenBuffers(1, &quadVBOId);

    glBindVertexArray(quadVAOId);

    char* vsrc = read_file(resource_path("shaders/texture.vsh"));
    char* fsrc = read_file(resource_path("shaders/textureRect.fsh"));

    GLuint prog = glCreateProgram();

    GLuint vertShader = 0, fragShader = 0;
    const GLchar* vertSource = vsrc;
    const GLchar* fragSource = fsrc;
    glueCompileShader(GL_VERTEX_SHADER, 1, &vertSource, &vertShader);
    glueCompileShader(GL_FRAGMENT_SHADER, 1, &fragSource, &fragShader);
    glAttachShader(prog, vertShader);
    glAttachShader(prog, fragShader);

    // TODO: do we need this?
    glBindAttribLocation(prog, ATTRIB_VERTEX, "inVertex");
    glBindAttribLocation(prog, ATTRIB_TEXCOORD, "inTexCoord");

    glueLinkProgram(prog);

    program->uniform[UNIFORM_MVP] = glGetUniformLocation(prog, "MVP");
    program->uniform[UNIFORM_TEXTURE] = glGetUniformLocation(prog, "tex");
    program->id = prog;

    if (vertShader) glDeleteShader(vertShader);
    if (fragShader) glDeleteShader(fragShader);
    free(vsrc);
    free(fsrc);

    glBindVertexArray(0);
}

- (void)initQuad:(IOSurfaceRef)surface {
    GLfloat logoWidth = (GLfloat)IOSurfaceGetWidth(surface);
    GLfloat logoHeight = (GLfloat)IOSurfaceGetHeight(surface);
    GLfloat quad[] = {  // x, y            s, t
        -1.0f, -1.0f, 0.0f, 0.0f,       1.0f, -1.0f, logoWidth, 0.0f,
        -1.0f, 1.0f,  0.0f, logoHeight, 1.0f, 1.0f,  logoWidth, logoHeight};

    glBindVertexArray(quadVAOId);
    glBindBuffer(GL_ARRAY_BUFFER, quadVBOId);
    glBufferData(GL_ARRAY_BUFFER, sizeof(quad), quad, GL_STATIC_DRAW);
    // positions
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat), NULL);
    // texture coordinates
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat),
                          (const GLvoid*)(2 * sizeof(GLfloat)));

    quadInit = true;
}

- (void)tick {
    if (!current) return;

    IOSurfaceRef prev_prev = prev;
    if (pthread_mutex_lock(&mutex)) return;
    prev = current;
    current = NULL;
    pthread_mutex_unlock(&mutex);

    if (prev_prev == prev) return;

    if (prev_prev) {
        IOSurfaceDecrementUseCount(prev_prev);
        CFRelease(prev_prev);
    }
}

- (void)render {
    if (!prev) return;

    GLuint name;
    IOSurfaceRef surface = (IOSurfaceRef)prev;

    GLsizei width = (GLsizei)IOSurfaceGetWidth(surface);
    GLsizei height = (GLsizei)IOSurfaceGetHeight(surface);

    glViewport(0, 0, width, height);
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);

    glGenTextures(1, &name);

    glBindTexture(GL_TEXTURE_RECTANGLE, name);
    // At the moment, CGLTexImageIOSurface2D requires the GL_TEXTURE_RECTANGLE target
    CGLTexImageIOSurface2D(self.openGLContext.CGLContextObj, GL_TEXTURE_RECTANGLE, GL_RGBA, width,
                           height, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, surface, 0);
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    if (!quadInit) [self initQuad:surface];

    glUseProgram(program->id);

    // const GLfloat mvp[] = {
    //     1.0f, 0.0f, 0.0f, 0.0f,  //
    //     0.0f, 1.0f, 0.0f, 0.0f,  //
    //     0.0f, 0.0f, 1.0f, 0.0f,  //
    //     0.0f, 0.0f, 0.0f, 1.0f,  //
    // };
    GLKMatrix4 mvp = GLKMatrix4Identity;
    mvp = GLKMatrix4Rotate(mvp, M_PI, 1.0, 0.0, 0.0);

    glUniformMatrix4fv(program->uniform[UNIFORM_MVP], 1, GL_FALSE, mvp.m);

    glUniform1i(program->uniform[UNIFORM_TEXTURE], 0);

    glBindTexture(GL_TEXTURE_RECTANGLE, name);
    glEnable(GL_TEXTURE_RECTANGLE);

    glBindVertexArray(quadVAOId);
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    glDisableVertexAttribArray(ATTRIB_VERTEX);
    glDisableVertexAttribArray(ATTRIB_TEXCOORD);
    glDisable(GL_TEXTURE_RECTANGLE);
}

@end

@implementation ScreenCaptureDelegate

- (instancetype)initWithCaptureView:(CaptureView*)theCaptureView {
    self = [super init];
    if (self) {
        captureView = theCaptureView;
    }
    return self;
}

- (void)stream:(SCStream*)stream
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
                   ofType:(SCStreamOutputType)type {
    if (type == SCStreamOutputTypeScreen) {
        [self update:sampleBuffer];
        [self drawView];
    }
}

- (void)update:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef image_buffer = CMSampleBufferGetImageBuffer(sampleBuffer);

    CVPixelBufferLockBaseAddress(image_buffer, 0);
    IOSurfaceRef frame_surface = CVPixelBufferGetIOSurface(image_buffer);
    CVPixelBufferUnlockBaseAddress(image_buffer, 0);

    IOSurfaceRef prev_current = NULL;

    if (frame_surface && !pthread_mutex_lock(&captureView->mutex)) {
        prev_current = captureView->current;
        captureView->current = frame_surface;
        CFRetain(captureView->current);
        IOSurfaceIncrementUseCount(captureView->current);

        pthread_mutex_unlock(&captureView->mutex);
    }

    if (prev_current) {
        IOSurfaceDecrementUseCount(prev_current);
        CFRelease(prev_current);
    }
}

- (void)drawView {
    [captureView.openGLContext makeCurrentContext];
    CGLLockContext(captureView.openGLContext.CGLContextObj);

    [captureView tick];
    [captureView render];

    [captureView.openGLContext flushBuffer];

    CGLUnlockContext(captureView.openGLContext.CGLContextObj);
}

@end
