#import "model/capture_engine.h"
#import "util/file_util.h"
#import "util/log_util.h"
#import "util/shader_util.h"
#import <GLKit/GLKit.h>
#import <OpenGL/gl3.h>
#import <pthread.h>

struct screen_capture {
    SCStream* disp;
    SCStreamConfiguration* stream_config;

    IOSurfaceRef current, prev;

    pthread_mutex_t mutex;

    CGWindowID window;  // TODO: use this to match and kill streams when they become nil

    NSOpenGLContext* context;

    capture_engine* capture_engine;
};

enum { UNIFORM_MVP, UNIFORM_TEXTURE, NUM_UNIFORMS };
enum { ATTRIB_VERTEX, ATTRIB_TEXCOORD, NUM_ATTRIBS };

struct program_info_t {
    GLuint id;
    GLint uniform[NUM_UNIFORMS];
};

capture_engine::capture_engine(NSOpenGLContext* context, NSRect frame, SCWindow* target_window) {
    capture_delegate = [[ScreenCaptureDelegate alloc] init];
    sc = new screen_capture();
    program = new program_info_t();

    capture_delegate.sc = sc;

    setup_shaders();

    sc->context = context;

    sc->capture_engine = this;

    pthread_mutex_init(&sc->mutex, NULL);

    // TODO: from start_capture(); clean this up
    SCContentFilter* content_filter;

    sc->stream_config = [[SCStreamConfiguration alloc] init];

    sc->window = target_window.windowID;
    content_filter = [[SCContentFilter alloc] initWithDesktopIndependentWindow:target_window];

    sc->stream_config.width = frame.size.width * 2;
    sc->stream_config.height = frame.size.height * 2;

    sc->stream_config.queueDepth = 8;
    sc->stream_config.showsCursor = false;
    sc->stream_config.pixelFormat = 'BGRA';
    sc->stream_config.colorSpaceName = kCGColorSpaceDisplayP3;
    // TODO: do these have any effect?
    sc->stream_config.scalesToFit = true;
    // sc->stream_config.backgroundColor = CGColorGetConstantColor(kCGColorClear);

    sc->disp = [[SCStream alloc] initWithFilter:content_filter
                                  configuration:sc->stream_config
                                       delegate:nil];

    NSError* error = nil;
    BOOL did_add_output = [sc->disp addStreamOutput:capture_delegate
                                               type:SCStreamOutputTypeScreen
                                 sampleHandlerQueue:nil
                                              error:&error];
    if (!did_add_output) {
        custom_log(OS_LOG_TYPE_ERROR, @"capture-engine", error.localizedFailureReason);
        // return !did_add_output;
    }
}

bool capture_engine::start_capture() {
    dispatch_semaphore_t stream_start_completed = dispatch_semaphore_create(0);

    __block BOOL is_success = false;
    [sc->disp startCaptureWithCompletionHandler:^(NSError* _Nullable error) {
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
    [sc->disp stopCaptureWithCompletionHandler:^(NSError* _Nullable error) {
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
    if (!sc->current) return;

    IOSurfaceRef prev_prev = sc->prev;
    if (pthread_mutex_lock(&sc->mutex)) return;
    sc->prev = sc->current;
    sc->current = NULL;
    pthread_mutex_unlock(&sc->mutex);

    if (prev_prev == sc->prev) return;

    if (prev_prev) {
        IOSurfaceDecrementUseCount(prev_prev);
        CFRelease(prev_prev);
    }
}

void capture_engine::render() {
    if (!sc->prev) return;

    GLuint name;
    CGLContextObj cgl_ctx = sc->context.CGLContextObj;
    IOSurfaceRef surface = (IOSurfaceRef)sc->prev;

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

static inline void screen_stream_video_update(struct screen_capture* sc,
                                              CMSampleBufferRef sample_buffer) {
    CVImageBufferRef image_buffer = CMSampleBufferGetImageBuffer(sample_buffer);

    CVPixelBufferLockBaseAddress(image_buffer, 0);
    IOSurfaceRef frame_surface = CVPixelBufferGetIOSurface(image_buffer);
    CVPixelBufferUnlockBaseAddress(image_buffer, 0);

    IOSurfaceRef prev_current = NULL;

    if (frame_surface && !pthread_mutex_lock(&sc->mutex)) {
        prev_current = sc->current;
        sc->current = frame_surface;
        CFRetain(sc->current);
        IOSurfaceIncrementUseCount(sc->current);

        pthread_mutex_unlock(&sc->mutex);
    }

    if (prev_current) {
        IOSurfaceDecrementUseCount(prev_current);
        CFRelease(prev_current);
    }
}

void draw_view(struct screen_capture* sc) {
    CGLContextObj cgl_ctx = sc->context.CGLContextObj;

    [sc->context makeCurrentContext];
    CGLLockContext(cgl_ctx);

    sc->capture_engine->tick();
    sc->capture_engine->render();

    [sc->context flushBuffer];

    CGLUnlockContext(cgl_ctx);
}

@implementation ScreenCaptureDelegate

- (void)stream:(SCStream*)stream
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
                   ofType:(SCStreamOutputType)type {
    if (type == SCStreamOutputTypeScreen) {
        screen_stream_video_update(self.sc, sampleBuffer);
        draw_view(self.sc);
    }
}

@end
