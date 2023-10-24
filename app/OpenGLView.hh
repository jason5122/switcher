#import "Renderer.hpp"
#import <Cocoa/Cocoa.h>

@interface OpenGLView : NSOpenGLView {
    CVDisplayLinkRef displayLink;
    Renderer* renderer;
}

- (void)drawView;

@end
