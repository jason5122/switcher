#import <Cocoa/Cocoa.h>

struct CppMembers;

@interface OpenGLView : NSOpenGLView {
    struct CppMembers* _cppMembers;
    int idx;
    bool hasStarted;
}

- (id)initWithFrame:(NSRect)frame index:(int)idx;
- (void)startCapture;

@end
