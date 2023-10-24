#import "controller/view_controller.h"
#import "view/opengl_view.h"

@implementation ViewController

- (instancetype)initWithBounds:(CGRect)bounds {
    self = [super init];
    if (self) {
        contentSize = bounds;
    }
    return self;
}

- (void)loadView {
    id view = [[OpenGLView alloc] initWithFrame:contentSize];
    self.view = view;
}

@end
