#import "model/capture_engine.h"
#import "model/renderer.h"
#import "util/log_util.h"
#import "view/opengl_view.h"
#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>

struct CppMembers {
    Renderer* renderer;
    CaptureEngine* capture_engine;
};

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
    // NSOpenGLPixelFormatAttribute attribs[] = {
    //     NSOpenGLPFADoubleBuffer,
    //     NSOpenGLPFAAllowOfflineRenderers,
    //     NSOpenGLPFAMultisample,
    //     1,
    //     NSOpenGLPFASampleBuffers,
    //     1,
    //     NSOpenGLPFASamples,
    //     4,
    //     NSOpenGLPFAColorSize,
    //     32,
    //     NSOpenGLPFADepthSize,
    //     32,
    //     NSOpenGLPFAOpenGLProfile,
    //     NSOpenGLProfileVersion3_2Core,
    //     0,
    // };

    NSOpenGLPixelFormatAttribute attribs[] = {
        NSOpenGLPFAAccelerated,
        NSOpenGLPFANoRecovery,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFADepthSize,
        24,
        0,
    };

    NSOpenGLPixelFormat* pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
    if (!pf) {
        NSLog(@"Failed to create pixel format.");
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

    if ([self initImageData]) [self loadTexturesWithClientStorage];

    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glEnable(GL_TEXTURE_RECTANGLE_EXT);

    // Synchronize buffer swaps with vertical refresh rate
    GLint one = 1;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self.openGLContext setValues:&one forParameter:NSOpenGLCPSwapInterval];
#pragma clang diagnostic pop

    glEnable(GL_MULTISAMPLE);
}

- (void)setupDisplayLink {
    // Create a display link capable of being used with all active displays
    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);

    // Set the renderer output callback function
    CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, (__bridge void*)self);

    // Set the display link for the current renderer
    CGLContextObj cglContext = self.openGLContext.CGLContextObj;
    CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);

    // Activate the display link
    CVDisplayLinkStart(displayLink);
}

- (void)prepareOpenGL {
    [super prepareOpenGL];
    [self initGL];
    [self setupDisplayLink];

    _cppMembers->renderer = new Renderer();
    _cppMembers->capture_engine = new CaptureEngine(self.openGLContext, texture);

    [self drawView];  // initial draw call
}

- (void)update {
    [super update];
    [self.openGLContext update];
}

- (void)drawView {
    [self.openGLContext makeCurrentContext];

    // We draw on a secondary thread through the display link
    // lock to avoid the threads from accessing the context simultaneously
    CGLLockContext(self.openGLContext.CGLContextObj);

    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    glViewport(0, 0, width * 2, height * 2);
    // glViewport(0, 0, width, height);

    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    // // _cppMembers->renderer->render(width, height);
    _cppMembers->capture_engine->screen_capture_video_tick();
    _cppMembers->capture_engine->screen_capture_video_render();
    // _cppMembers->capture_engine->draw2();

    [self.openGLContext flushBuffer];

    CGLUnlockContext(self.openGLContext.CGLContextObj);
}

- (void)loadTexturesWithClientStorage {
    glGenTextures(1, &texture);

    glBindTexture(GL_TEXTURE_RECTANGLE_EXT, texture);

    glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA, TEXTURE_WIDTH, TEXTURE_HEIGHT, 0, GL_BGRA,
                 GL_UNSIGNED_INT_8_8_8_8_REV, data);

    glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
}

- (BOOL)getImageData:(GLubyte*)imageData fromPath:(NSString*)path {
    NSUInteger width, height;
    NSURL* url = nil;
    CGImageSourceRef src;
    CGImageRef image;
    CGContextRef context = nil;
    CGColorSpaceRef colorSpace;

    url = [NSURL fileURLWithPath:path];
    src = CGImageSourceCreateWithURL((CFURLRef)url, NULL);

    if (!src) {
        log_with_type(OS_LOG_TYPE_ERROR, @"No image", @"opengl-view");
        return NO;
    }

    image = CGImageSourceCreateImageAtIndex(src, 0, NULL);
    CFRelease(src);

    width = CGImageGetWidth(image);
    height = CGImageGetHeight(image);

    colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3);
    context = CGBitmapContextCreate(imageData, width, height, 8, 4 * width, colorSpace,
                                    kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
    CGColorSpaceRelease(colorSpace);

    // Core Graphics referential is flipped on the x- and y-axis compared to OpenGL referential
    // Flip the Core Graphics context here
    // An alternative is to use flipped OpenGL texture coordinates when drawing textures
    CGContextTranslateCTM(context, width, height);
    CGContextScaleCTM(context, -1.0, -1.0);

    // Set the blend mode to copy before drawing since the previous contents of memory aren't used.
    // This avoids unnecessary blending.
    CGContextSetBlendMode(context, kCGBlendModeCopy);

    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);

    CGContextRelease(context);
    CGImageRelease(image);

    return YES;
}

- (BOOL)initImageData {
    // This holds the data of all textures
    data = (GLubyte*)calloc(TEXTURE_WIDTH * TEXTURE_HEIGHT * 4, sizeof(GLubyte));

    NSString* path = [[NSBundle mainBundle] pathForResource:@"image" ofType:@"jpg"];

    if (!path) {
        log_with_type(OS_LOG_TYPE_ERROR, @"No valid path", @"opengl-view");
        return NO;
    }

    // Point to the current texture
    GLubyte* imageData = data;

    if (![self getImageData:imageData fromPath:path]) return NO;

    return YES;
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
