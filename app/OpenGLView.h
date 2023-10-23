#import "CaptureEngine.hh"
#import "Renderer.hh"
#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl3.h>

@interface OpenGLView : NSOpenGLView {
    CVDisplayLinkRef displayLink;
    Renderer* renderer;
}

- (void)drawView;

@end
