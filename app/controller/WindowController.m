#import "WindowController.h"
#import "view/OpenGLView.h"

@implementation WindowController

- (instancetype)init {
    self = [super init];
    if (self) {
        CGFloat width = 400;
        CGFloat height = 250;
        CGFloat padding = 60;
        NSRect windowRect = NSMakeRect(0, 0, (width + padding) * 2, height + padding);
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
            CGFloat x = padding / 2;
            CGFloat y = padding / 2;
            x += (width + padding) * i;
            screenCapture.frameOrigin = CGPointMake(x, y);
            [visualEffect addSubview:screenCapture];
        }

        // TODO: experimental; consider adding/removing
        // window.ignoresMouseEvents = true;

        // TODO: debug; remove
        // window.movableByWindowBackground = true;
    }
    return self;
}

- (void)setupWindowAndSpace {
    [window center];
    [window setFrameAutosaveName:@"switcher"];
    [window makeKeyAndOrderFront:nil];

    [space addWindow:window];
}

@end
