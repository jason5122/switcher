#import <Cocoa/Cocoa.h>

struct CppMembers;

@interface OpenGLView : NSOpenGLView {
    struct CppMembers* _cppMembers;
}

@end
