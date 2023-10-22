#import "BoingRenderer.hh"
#import "CaptureEngine.hh"
#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl3.h>

@interface OpenGLView : NSOpenGLView {
    NSOpenGLPixelFormat* pixelFormat;
    CVDisplayLinkRef displayLink;
    BoingRenderer* renderer;
    BOOL enableMultisample;
    BOOL isPaused;
    uint32_t pressed_keys;
    NSTrackingArea* trackingArea;
}

- (void)drawView;

@end
