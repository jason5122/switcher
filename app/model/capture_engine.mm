#import "model/capture_engine.h"
#import "util/file_util.h"
#import "util/log_util.h"
#import "util/shader_util.h"
#import <GLKit/GLKit.h>
#import <OpenGL/gl3.h>
#import <pthread.h>

// TODO: merge this whole file with CaptureView?

struct screen_capture {
    capture_engine* capture_engine;
};

enum { UNIFORM_MVP, UNIFORM_TEXTURE, NUM_UNIFORMS };
enum { ATTRIB_VERTEX, ATTRIB_TEXCOORD, NUM_ATTRIBS };

struct program_info_t {
    GLuint id;
    GLint uniform[NUM_UNIFORMS];
};

capture_engine::capture_engine(SCWindow* targetWindow, CaptureView* captureView) {
    this->captureView = captureView;

    sc = new screen_capture();
    program = new program_info_t();

    captureDelegate = [[ScreenCaptureDelegate alloc] init:captureView screenCapture:sc];

    setup_shaders();

    sc->capture_engine = this;

    pthread_mutex_init(&captureView->mutex, NULL);

    captureView->streamConfig = [[SCStreamConfiguration alloc] init];
    captureView->streamConfig.width = captureView.frame.size.width * 2;
    captureView->streamConfig.height = captureView.frame.size.height * 2;
    captureView->streamConfig.queueDepth = 8;
    captureView->streamConfig.showsCursor = false;
    captureView->streamConfig.pixelFormat = 'BGRA';
    captureView->streamConfig.colorSpaceName = kCGColorSpaceDisplayP3;

    SCContentFilter* contentFilter =
        [[SCContentFilter alloc] initWithDesktopIndependentWindow:targetWindow];
    captureView->disp = [[SCStream alloc] initWithFilter:contentFilter
                                           configuration:captureView->streamConfig
                                                delegate:nil];

    NSError* error = nil;
    BOOL did_add_output = [captureView->disp addStreamOutput:captureDelegate
                                                        type:SCStreamOutputTypeScreen
                                          sampleHandlerQueue:nil
                                                       error:&error];
    if (!did_add_output) {
        custom_log(OS_LOG_TYPE_ERROR, @"capture-engine", error.localizedFailureReason);
    }
}

bool capture_engine::start_capture() {
    dispatch_semaphore_t stream_start_completed = dispatch_semaphore_create(0);

    __block BOOL is_success = false;
    [captureView->disp startCaptureWithCompletionHandler:^(NSError* _Nullable error) {
      is_success = (BOOL)(error == nil);
      if (!is_success) {
          custom_log(OS_LOG_TYPE_ERROR, @"capture-engine", error.localizedFailureReason);
      }
      dispatch_semaphore_signal(stream_start_completed);
    }];
    dispatch_semaphore_wait(stream_start_completed, DISPATCH_TIME_FOREVER);
    return is_success;
}

bool capture_engine::stop_capture() {
    dispatch_semaphore_t stream_stop_completed = dispatch_semaphore_create(0);

    __block BOOL is_success = false;
    [captureView->disp stopCaptureWithCompletionHandler:^(NSError* _Nullable error) {
      is_success = (BOOL)(error == nil);
      if (!is_success) {
          custom_log(OS_LOG_TYPE_ERROR, @"capture-engine", error.localizedFailureReason);
      }
      dispatch_semaphore_signal(stream_stop_completed);
    }];
    dispatch_semaphore_wait(stream_stop_completed, DISPATCH_TIME_FOREVER);
    return is_success;
}

void capture_engine::setup_shaders() {
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

void capture_engine::init_quad(IOSurfaceRef surface) {
    GLfloat logoWidth = (GLfloat)IOSurfaceGetWidth(surface);
    GLfloat logoHeight = (GLfloat)IOSurfaceGetHeight(surface);
    GLfloat quad[] = {// x, y            s, t
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

    quadInit = YES;
}

void capture_engine::tick() {
    if (!captureView->current) return;

    IOSurfaceRef prev_prev = captureView->prev;
    if (pthread_mutex_lock(&captureView->mutex)) return;
    captureView->prev = captureView->current;
    captureView->current = NULL;
    pthread_mutex_unlock(&captureView->mutex);

    if (prev_prev == captureView->prev) return;

    if (prev_prev) {
        IOSurfaceDecrementUseCount(prev_prev);
        CFRelease(prev_prev);
    }
}

void capture_engine::render() {
    if (!captureView->prev) return;

    GLuint name;
    CGLContextObj cgl_ctx = captureView.openGLContext.CGLContextObj;
    IOSurfaceRef surface = (IOSurfaceRef)captureView->prev;

    GLsizei width = (GLsizei)IOSurfaceGetWidth(surface);
    GLsizei height = (GLsizei)IOSurfaceGetHeight(surface);

    glViewport(0, 0, width, height);
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);

    glGenTextures(1, &name);

    glBindTexture(GL_TEXTURE_RECTANGLE, name);
    // At the moment, CGLTexImageIOSurface2D requires the GL_TEXTURE_RECTANGLE target
    CGLTexImageIOSurface2D(cgl_ctx, GL_TEXTURE_RECTANGLE, GL_RGBA, width, height, GL_BGRA,
                           GL_UNSIGNED_INT_8_8_8_8_REV, surface, 0);
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    if (!quadInit) init_quad(surface);

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

@implementation ScreenCaptureDelegate

- (instancetype)init:(CaptureView*)theCaptureView screenCapture:(screen_capture*)theSc {
    self = [super init];
    if (self) {
        captureView = theCaptureView;
        sc = theSc;
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
    CGLContextObj cgl_ctx = captureView.openGLContext.CGLContextObj;

    [captureView.openGLContext makeCurrentContext];
    CGLLockContext(cgl_ctx);

    sc->capture_engine->tick();
    sc->capture_engine->render();

    [captureView.openGLContext flushBuffer];

    CGLUnlockContext(cgl_ctx);
}

@end
