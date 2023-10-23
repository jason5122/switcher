#import "Renderer.hh"
#import "CaptureEngine.hh"
#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl3.h>

@interface OpenGLView : NSOpenGLView {
    NSOpenGLPixelFormat* pixelFormat;
    CVDisplayLinkRef displayLink;
    Renderer* renderer;
    BOOL enableMultisample;
    BOOL isPaused;
    uint32_t pressed_keys;
    NSTrackingArea* trackingArea;
}

- (void)drawView;

@end
