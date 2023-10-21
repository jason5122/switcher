#include "OpenGLView.h"
#include "ViewController.h"

@implementation ViewController

- (instancetype)initWithBounds:(CGRect)bounds {
    self = [super init];
    if (self) {
        contentSize = bounds;
    }
    return self;
}

// this is faster than NSOpenGLView reshape(), but why?
- (void)resizeView {
    [(OpenGLView*)self.view drawView];
}

- (void)loadView {
    id view = [[OpenGLView alloc] initWithFrame:contentSize];
    self.view = view;
}

@end
