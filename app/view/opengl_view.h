#import <Cocoa/Cocoa.h>

struct CppMembers;

@interface OpenGLView : NSOpenGLView {
    CVDisplayLinkRef displayLink;
    struct CppMembers* _cppMembers;

    GLuint texture;
    GLubyte* data;
}

- (void)drawView;

@end
