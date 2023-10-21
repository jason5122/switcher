#import "OpenGLView.h"

enum {
    up_key_pressed = 1,
    down_key_pressed = 2,
    left_key_pressed = 4,
    right_key_pressed = 8,
    zoom_in_key_pressed = 16,
    zoom_out_key_pressed = 32,
    pause_key_pressed = 64
};

@implementation OpenGLView

- (CVReturn)getFrameForTime:(const CVTimeStamp*)outputTime {
    // There is no autorelease pool when this method is called
    // because it will be called from a background thread
    // It's important to create one or you will leak objects
    @autoreleasepool {
        [self drawView];
        [self readInputs];
    }
    return kCVReturnSuccess;
}

// This is the renderer output callback function
static CVReturn
MyDisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now,
                      const CVTimeStamp* outputTime, CVOptionFlags flagsIn,
                      CVOptionFlags* flagsOut, void* displayLinkContext) {
    CVReturn result =
        [(__bridge OpenGLView*)displayLinkContext getFrameForTime:outputTime];
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

    NSOpenGLPixelFormat* pf =
        [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
    if (!pf) {
        NSLog(@"Failed to create pixel format.");
        return nil;
    }

    self = [super initWithFrame:frame pixelFormat:pf];
    if (self) {
        enableMultisample = YES;
        isPaused = NO;
    }

    return self;
}

- (void)mouseEntered:(NSEvent*)event {
    [super mouseEntered:event];
    [[NSCursor IBeamCursor] set];
}

- (void)mouseExited:(NSEvent*)event {
    [super mouseExited:event];
    [[NSCursor arrowCursor] set];
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    if (trackingArea != nil) {
        [self removeTrackingArea:trackingArea];
    }

    int opts = (NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways);
    trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                options:opts
                                                  owner:self
                                               userInfo:nil];
    [self addTrackingArea:trackingArea];
}

- (void)initGL {
    [[self openGLContext] makeCurrentContext];

    // Synchronize buffer swaps with vertical refresh rate
    GLint one = 1;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[self openGLContext] setValues:&one forParameter:NSOpenGLCPSwapInterval];
#pragma clang diagnostic pop

    if (enableMultisample) glEnable(GL_MULTISAMPLE);
}

- (void)setupDisplayLink {
    // Create a display link capable of being used with all active displays
    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);

    // Set the renderer output callback function
    CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback,
                                   (__bridge void*)self);

    // Set the display link for the current renderer
    CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
    CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext,
                                                      cglPixelFormat);

    // Activate the display link
    CVDisplayLinkStart(displayLink);
}

- (void)prepareOpenGL {
    [super prepareOpenGL];
    [self initGL];
    [self setupDisplayLink];

    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    renderer = new BoingRenderer(width, height);
    [self drawView];  // initial draw call
}

- (void)update {
    [super update];
    [[self openGLContext] update];
}

- (void)drawView {
    if (isPaused) return;

    [[self openGLContext] makeCurrentContext];

    // We draw on a secondary thread through the display link
    // lock to avoid the threads from accessing the context simultaneously
    CGLLockContext([[self openGLContext] CGLContextObj]);

    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    glViewport(0, 0, width * 2, height * 2);

    // FIXME: this call is needed for resizeView() not to segfault
    if (!renderer) renderer = new BoingRenderer(width, height);

    uint64_t start = clock_gettime_nsec_np(CLOCK_MONOTONIC);
    renderer->render(width, height);
    uint64_t end = clock_gettime_nsec_np(CLOCK_MONOTONIC);
    std::cout << (end - start) / 1e6 << " ms\n";

    [[self openGLContext] flushBuffer];

    CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void)readInputs {
    if (pressed_keys & up_key_pressed) renderer->y -= 0.1f;
    if (pressed_keys & down_key_pressed) renderer->y += 0.1f;
    if (pressed_keys & left_key_pressed) renderer->x += 0.1f;
    if (pressed_keys & right_key_pressed) renderer->x -= 0.1f;
    if (pressed_keys & zoom_in_key_pressed) renderer->z += 0.1f;
    if (pressed_keys & zoom_out_key_pressed) renderer->z -= 0.1f;
    if (pressed_keys & pause_key_pressed) {
        // isPaused = !isPaused;
        // renderer->can_rotate = !renderer->can_rotate;
    }
}

- (void)dealloc {
    // Stop the display link BEFORE releasing anything in the view
    // otherwise the display link thread may call into the view and crash
    // when it encounters something that has been released
    CVDisplayLinkStop(displayLink);
    CVDisplayLinkRelease(displayLink);
}

- (void)keyDown:(NSEvent*)event {
    NSString* characters = [event characters];
    for (uint32_t k = 0; k < characters.length; k++) {
        unichar key = [characters characterAtIndex:k];
        switch (key) {
        case ' ':
            pressed_keys |= pause_key_pressed;
            isPaused = !isPaused;
            // renderer->can_rotate = !renderer->can_rotate;
            break;
        case '0':
            renderer->x = 0.0f;
            renderer->y = 0.0f;
            break;
        case 'i':
            [self drawView];
            break;

        case 'f':
            pressed_keys |= right_key_pressed;
            break;
        case 's':
            pressed_keys |= left_key_pressed;
            break;
        case 'e':
            pressed_keys |= up_key_pressed;
            break;
        case 'd':
            pressed_keys |= down_key_pressed;
            break;
        case 'j':
            pressed_keys |= zoom_in_key_pressed;
            break;
        case 'k':
            pressed_keys |= zoom_out_key_pressed;
            break;
        }
    }
}

- (void)keyUp:(NSEvent*)event {
    NSString* characters = event.characters;
    for (uint32_t k = 0; k < characters.length; k++) {
        unichar key = [characters characterAtIndex:k];
        switch (key) {
        case ' ':
            pressed_keys &= ~pause_key_pressed;
            break;
        case 'f':
            pressed_keys &= ~right_key_pressed;
            break;
        case 's':
            pressed_keys &= ~left_key_pressed;
            break;
        case 'e':
            pressed_keys &= ~up_key_pressed;
            break;
        case 'd':
            pressed_keys &= ~down_key_pressed;
            break;
        case 'j':
            pressed_keys &= ~zoom_in_key_pressed;
            break;
        case 'k':
            pressed_keys &= ~zoom_out_key_pressed;
            break;
        }
    }
}

- (void)scrollWheel:(NSEvent*)event {
    if (event.type == NSEventTypeScrollWheel) {
        float delta_x = event.scrollingDeltaX * 0.01;
        float delta_y = -event.scrollingDeltaY * 0.01;
        renderer->x += delta_x;
        renderer->y += delta_y;
        // [self drawView];
    }
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

@end
