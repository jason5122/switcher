#import "WindowController.h"
#import "util/log_util.h"
#import "view/OpenGLView.h"
#import <vector>

struct CppMembers {
    std::vector<OpenGLView*> screen_captures;
};

@implementation WindowController

- (instancetype)init {
    self = [super init];
    if (self) {
        _cppMembers = new CppMembers;

        // CGFloat width = 400, height = 250;
        CGFloat width = 320, height = 200;
        // CGFloat width = 200, height = 125;
        // TODO: separate into left- and right-padding
        CGFloat padding = 20;
        NSRect windowRect =
            NSMakeRect(0, 0, (width + padding) * 2 + padding, height + padding * 2);
        NSRect screenCaptureRect = NSMakeRect(0, 0, width, height);

        space = [[CGSSpace alloc] initWithLevel:1];

        int mask = NSWindowStyleMaskFullSizeContentView;
        window = [[NSWindow alloc] initWithContentRect:windowRect
                                             styleMask:mask
                                               backing:NSBackingStoreBuffered
                                                 defer:false];
        window.hasShadow = false;
        window.backgroundColor = NSColor.clearColor;

        NSVisualEffectView* visualEffect = [[NSVisualEffectView alloc] init];
        visualEffect.blendingMode = NSVisualEffectBlendingModeBehindWindow;
        visualEffect.material = NSVisualEffectMaterialHUDWindow;
        visualEffect.state = NSVisualEffectStateActive;

        visualEffect.wantsLayer = true;
        visualEffect.layer.cornerRadius = 9.0;

        window.contentView = visualEffect;

        for (int i = 0; i < 2; i++) {
            OpenGLView* screenCapture = [[OpenGLView alloc] initWithFrame:screenCaptureRect
                                                                    index:i];
            CGFloat x = padding;
            CGFloat y = padding;
            x += (width + padding) * i;
            screenCapture.frameOrigin = CGPointMake(x, y);
            [visualEffect addSubview:screenCapture];

            _cppMembers->screen_captures.push_back(screenCapture);
        }

        // TODO: experimental; consider adding/removing
        // window.ignoresMouseEvents = true;

        // TODO: debug; remove
        // window.movableByWindowBackground = true;
    }
    return self;
}

- (void)setupWindowAndSpace {
    for (OpenGLView* screenCapture : _cppMembers->screen_captures) {
        [screenCapture startCapture];
    }

    // actually center window
    NSSize screenSize = NSScreen.mainScreen.frame.size;
    NSSize panelSize = window.frame.size;
    CGFloat x = fmax(screenSize.width - panelSize.width, 0) * 0.5;
    CGFloat y = fmax(screenSize.height - panelSize.height, 0) * 0.5;
    window.frameOrigin = NSMakePoint(x, y);

    // [window center];
    // [window setFrameAutosaveName:@"switcher"];
    [window makeKeyAndOrderFront:nil];

    [space addWindow:window];
}

@end
