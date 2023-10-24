#import "model/capture_engine.h"
#import "util/log_util.h"
#import "view/opengl_view.h"
#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl3.h>

@implementation OpenGLView

- (CVReturn)getFrameForTime:(const CVTimeStamp*)outputTime {
    // There is no autorelease pool when this method is called
    // because it will be called from a background thread
    // It's important to create one or you will leak objects
    @autoreleasepool {
        [self drawView];
    }
    return kCVReturnSuccess;
}

// This is the renderer output callback function
static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now,
                                      const CVTimeStamp* outputTime, CVOptionFlags flagsIn,
                                      CVOptionFlags* flagsOut, void* displayLinkContext) {
    CVReturn result = [(__bridge OpenGLView*)displayLinkContext getFrameForTime:outputTime];
    return result;
}

- (id)initWithFrame:(NSRect)frame {
    // NOTE: to use integrated GPU:
    // 1. NSOpenGLPFAAllowOfflineRenderers when using NSOpenGL
    // 2. kCGLPFAAllowOfflineRenderers when using CGL
    NSOpenGLPixelFormatAttribute attribs[] = {NSOpenGLPFADoubleBuffer,
                                              NSOpenGLPFAAllowOfflineRenderers,
                                              NSOpenGLPFAMultisample,
                                              1,
                                              NSOpenGLPFASampleBuffers,
                                              1,
                                              NSOpenGLPFASamples,
                                              4,
                                              NSOpenGLPFAColorSize,
                                              32,
                                              NSOpenGLPFADepthSize,
                                              32,
                                              NSOpenGLPFAOpenGLProfile,
                                              NSOpenGLProfileVersion3_2Core,
                                              0};

    NSOpenGLPixelFormat* pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
    if (!pf) {
        NSLog(@"Failed to create pixel format.");
        return nil;
    }

    self = [super initWithFrame:frame pixelFormat:pf];

    return self;
}

- (void)initGL {
    [[self openGLContext] makeCurrentContext];

    // Synchronize buffer swaps with vertical refresh rate
    GLint one = 1;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[self openGLContext] setValues:&one forParameter:NSOpenGLCPSwapInterval];
#pragma clang diagnostic pop

    glEnable(GL_MULTISAMPLE);
}

- (void)setupDisplayLink {
    // Create a display link capable of being used with all active displays
    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);

    // Set the renderer output callback function
    CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, (__bridge void*)self);

    // Set the display link for the current renderer
    CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
    CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);

    // Activate the display link
    CVDisplayLinkStart(displayLink);
}

- (void)setupCaptureEngine {
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;

    CaptureEngine capture_engine = CaptureEngine(width, height);
    capture_engine.screen_capture_build_content_list();

    NSArray<SCWindow*>* windows = capture_engine.shareable_content.windows;

    const char* message = [[NSString stringWithFormat:@"%lu", [windows count]] UTF8String];
    log_default(message, "OpenGLView.mm");
    for (SCWindow* window in windows) {
        message = [[NSString stringWithFormat:@"%@", window.title] UTF8String];
        log_default(message, "OpenGLView.mm");
    }
}

- (void)prepareOpenGL {
    [super prepareOpenGL];
    [self initGL];
    [self setupDisplayLink];
    [self setupCaptureEngine];

    renderer = new Renderer();

    [self drawView];  // initial draw call
}

- (void)update {
    [super update];
    [[self openGLContext] update];
}

- (void)drawView {
    [[self openGLContext] makeCurrentContext];

    // We draw on a secondary thread through the display link
    // lock to avoid the threads from accessing the context simultaneously
    CGLLockContext([[self openGLContext] CGLContextObj]);

    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    glViewport(0, 0, width * 2, height * 2);

    // FIXME: this call is needed for resizeView() not to segfault
    if (!renderer) renderer = new Renderer();

    renderer->render(width, height);

    [[self openGLContext] flushBuffer];

    CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void)dealloc {
    // Stop the display link BEFORE releasing anything in the view
    // otherwise the display link thread may call into the view and crash
    // when it encounters something that has been released
    CVDisplayLinkStop(displayLink);
    CVDisplayLinkRelease(displayLink);
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

@end
