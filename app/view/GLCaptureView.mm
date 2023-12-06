#import "GLCaptureView.h"
#import "extensions/ScreenCaptureKit+InitWithId.h"
#import "util/log_util.h"
#import "util/shader_util.h"
#import <Cocoa/Cocoa.h>
#import <GLKit/GLKit.h>
#import <OpenGL/gl3.h>
#import <pthread.h>
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
    SCStreamConfiguration* streamConfig;

    program_info_t* program;
    GLuint quadVAOId, quadVBOId;

    dispatch_semaphore_t startedSem;
}

@property(nonatomic, getter=didQuadInit) bool quadInit;

@end

@implementation GLCaptureView

- (instancetype)initWithFrame:(NSRect)frame windowId:(CGWindowID)wid {
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
        _quadInit = false;

        startedSem = dispatch_semaphore_create(0);

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
        stream = [[SCStream alloc] initWithFilter:contentFilter
                                    configuration:streamConfig
                                         delegate:nil];

        captureOutput = [[GLCaptureOutput alloc] initWithView:self];

        NSError* error = nil;
        BOOL did_add_output = [stream addStreamOutput:captureOutput
                                                 type:SCStreamOutputTypeScreen
                                   sampleHandlerQueue:nil
                                                error:&error];
        if (!did_add_output) {
            custom_log(OS_LOG_TYPE_ERROR, @"capture-view", error.localizedFailureReason);
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

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),
                   ^{ [self startCapture]; });
}

- (void)startCapture {
    dispatch_semaphore_t stream_start_completed = dispatch_semaphore_create(0);

    __block BOOL success = false;
    [stream startCaptureWithCompletionHandler:^(NSError* _Nullable error) {
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
        dispatch_semaphore_signal(startedSem);
    }
}

- (void)stopCapture {
    dispatch_semaphore_wait(startedSem, DISPATCH_TIME_FOREVER);

    dispatch_semaphore_t stream_stop_completed = dispatch_semaphore_create(0);

    __block BOOL success = false;
    [stream stopCaptureWithCompletionHandler:^(NSError* _Nullable error) {
      success = (BOOL)(error == nil);
      if (!success) {
          custom_log(OS_LOG_TYPE_ERROR, @"capture-view", error.localizedFailureReason);
      }
      dispatch_semaphore_signal(stream_stop_completed);
    }];
    dispatch_semaphore_wait(stream_stop_completed, DISPATCH_TIME_FOREVER);

    if (!success) {
        custom_log(OS_LOG_TYPE_ERROR, @"capture-view", @"stop capture failed");
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
        IOSurfaceRef surface = [self createFrame:sampleBuffer];
        [captureView render:surface];
    }
}

- (IOSurfaceRef)createFrame:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    IOSurfaceRef frameSurface = CVPixelBufferGetIOSurface(imageBuffer);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);

    return frameSurface;
}

@end
