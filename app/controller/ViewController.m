#import "controller/ViewController.h"
#import "view/OpenGLView.h"

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
