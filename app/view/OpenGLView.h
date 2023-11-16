#import <Cocoa/Cocoa.h>

struct CppMembers;

@interface OpenGLView : NSOpenGLView {
    struct CppMembers* _cppMembers;
    int idx;
}

- (id)initWithFrame:(NSRect)frame index:(int)idx;

@end
