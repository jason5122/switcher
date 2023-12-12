#import "GLCaptureView.h"
#import "util/log_util.h"
#import "util/shader_util.h"
#import <Cocoa/Cocoa.h>
#import <GLKit/GLKit.h>
#import <OpenGL/gl3.h>
#import <string>

enum { UNIFORM_MVP, UNIFORM_TEXTURE, NUM_UNIFORMS };
enum { ATTRIB_VERTEX, ATTRIB_TEXCOORD, NUM_ATTRIBS };

struct program_info_t {
    GLuint id;
    GLint uniform[NUM_UNIFORMS];
};

@interface GLCaptureOutput : NSObject <SCStreamOutput> {
    // https://mobiarch.wordpress.com/2014/02/05/circular-reference-and-arc/
    __weak GLCaptureView* captureView;
}

- (instancetype)initWithView:(GLCaptureView*)captureView;

@end

// http://philjordan.eu/article/mixing-objective-c-c++-and-objective-c++
@interface GLCaptureView () {
    GLCaptureOutput* captureOutput;
    SCStream* stream;
    dispatch_semaphore_t startedSem;
    SCContentFilter* filter;
    SCStreamConfiguration* config;

    program_info_t* program;
    GLuint quadVAOId, quadVBOId;
}

@property(nonatomic, getter=didQuadInit) bool quadInit;

@end

@implementation GLCaptureView

- (instancetype)initWithFrame:(CGRect)frame configuration:(SCStreamConfiguration*)theConfig {
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
        custom_log(OS_LOG_TYPE_ERROR, @"gl-capture-view", @"failed to create pixel format");
        return nil;
    }

    self = [super initWithFrame:frame pixelFormat:pf];
    if (self) {
        _prepared = false;
        _quadInit = false;

        config = theConfig;

        startedSem = dispatch_semaphore_create(0);

        program = new program_info_t();
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

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
      [self startCapture];
      _prepared = true;
    });
}

- (void)updateWithFilter:(SCContentFilter*)theFilter {
    filter = theFilter;
}

- (void)startCapture {
    stream = [[SCStream alloc] initWithFilter:filter configuration:config delegate:nil];
    captureOutput = [[GLCaptureOutput alloc] initWithView:self];
    NSError* error = nil;
    BOOL did_add_output = [stream addStreamOutput:captureOutput
                                             type:SCStreamOutputTypeScreen
                               sampleHandlerQueue:nil
                                            error:&error];
    if (!did_add_output) {
        custom_log(OS_LOG_TYPE_ERROR, @"gl-capture-view", error.localizedDescription);
    }

    dispatch_semaphore_t stream_start_completed = dispatch_semaphore_create(0);
    [stream startCaptureWithCompletionHandler:^(NSError* _Nullable error) {
      if (error) {
          custom_log(OS_LOG_TYPE_ERROR, @"gl-capture-view", error.localizedDescription);
      }
      dispatch_semaphore_signal(stream_start_completed);
    }];
    dispatch_semaphore_wait(stream_start_completed, DISPATCH_TIME_FOREVER);

    dispatch_semaphore_signal(startedSem);
}

- (void)stopCapture {
    dispatch_semaphore_wait(startedSem, DISPATCH_TIME_FOREVER);

    dispatch_semaphore_t stream_stop_completed = dispatch_semaphore_create(0);
    [stream stopCaptureWithCompletionHandler:^(NSError* _Nullable error) {
      if (error) {
          custom_log(OS_LOG_TYPE_ERROR, @"gl-capture-view", error.localizedDescription);
      }
      dispatch_semaphore_signal(stream_stop_completed);
    }];
    dispatch_semaphore_wait(stream_stop_completed, DISPATCH_TIME_FOREVER);
}

- (void)update {
    [super update];
    [self.openGLContext update];
}

- (void)setupShaders {
    glGenVertexArrays(1, &quadVAOId);
    glGenBuffers(1, &quadVBOId);

    glBindVertexArray(quadVAOId);

    std::string vsrc =
#include "resources/shaders/texture.vsh"
        ;

    std::string fsrc =
#include "resources/shaders/textureRect.fsh"
        ;

    GLuint prog = glCreateProgram();

    GLuint vertShader = 0, fragShader = 0;
    const GLchar* vertSource = vsrc.c_str();
    const GLchar* fragSource = fsrc.c_str();
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

    _quadInit = true;
}

- (void)render:(IOSurfaceRef)surface {
    if (!surface) return;

    [self.openGLContext makeCurrentContext];
    CGLLockContext(self.openGLContext.CGLContextObj);

    GLsizei width = (GLsizei)IOSurfaceGetWidth(surface);
    GLsizei height = (GLsizei)IOSurfaceGetHeight(surface);

    glViewport(0, 0, width, height);
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);

    GLuint name;
    glGenTextures(1, &name);

    glBindTexture(GL_TEXTURE_RECTANGLE, name);
    // At the moment, CGLTexImageIOSurface2D requires the GL_TEXTURE_RECTANGLE target
    CGLTexImageIOSurface2D(self.openGLContext.CGLContextObj, GL_TEXTURE_RECTANGLE, GL_RGBA, width,
                           height, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, surface, 0);
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    if (!_quadInit) [self initQuad:surface];

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

    glDeleteTextures(1, &name);

    [self.openGLContext flushBuffer];
    CGLUnlockContext(self.openGLContext.CGLContextObj);
}

@end

@implementation GLCaptureOutput

- (instancetype)initWithView:(GLCaptureView*)theGLCaptureView {
    self = [super init];
    if (self) {
        captureView = theGLCaptureView;
    }
    return self;
}

- (void)stream:(SCStream*)stream
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
                   ofType:(SCStreamOutputType)type {
    if (type == SCStreamOutputTypeScreen) {
        IOSurfaceRef frame = [self createFrame:sampleBuffer];
        if (!frame) {
            // custom_log(OS_LOG_TYPE_ERROR, @"gl-capture-view", @"invalid frame");
            return;
        }
        // custom_log(OS_LOG_TYPE_DEFAULT, @"gl-capture-view", @"good");
        [captureView render:frame];
    }
}

- (IOSurfaceRef)createFrame:(CMSampleBufferRef)sampleBuffer {
    // Retrieve the array of metadata attachments from the sample buffer.
    CFArrayRef attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, false);
    if (attachmentsArray == nil || CFArrayGetCount(attachmentsArray) == 0) return nil;

    CFDictionaryRef attachments = (CFDictionaryRef)CFArrayGetValueAtIndex(attachmentsArray, 0);
    if (attachments == nil) return nil;

    // Validate the status of the frame. If it isn't `.complete`, return nil.
    CFTypeRef statusRawValue =
        CFDictionaryGetValue(attachments, (__bridge void*)SCStreamFrameInfoStatus);
    int status;
    bool result = CFNumberGetValue((CFNumberRef)statusRawValue, kCFNumberFloatType, &status);
    if (!result || status != SCFrameStatusComplete) return nil;

    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    IOSurfaceRef surface = CVPixelBufferGetIOSurface(imageBuffer);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    return surface;
}

@end
