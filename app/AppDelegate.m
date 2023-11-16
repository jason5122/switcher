#import "AppDelegate.h"
#import "view/OpenGLView.h"

@implementation AppDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        CGFloat width = 400;
        CGFloat height = 250;
        CGFloat padding = 60;
        NSRect windowRect = NSMakeRect(0, 0, width + padding, height + padding);
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

        OpenGLView* screenCapture = [[OpenGLView alloc] initWithFrame:screenCaptureRect];
        [visualEffect addSubview:screenCapture];
        screenCapture.frameOrigin = CGPointMake(padding / 2, padding / 2);

        // TODO: experimental; consider adding/removing
        // window.ignoresMouseEvents = true;

        // TODO: debug; remove
        // window.movableByWindowBackground = true;
    }
    return self;
}

- (void)applicationWillFinishLaunching:(NSNotification*)notification {
    [window center];
    [window setFrameAutosaveName:@"switcher"];
    [window makeKeyAndOrderFront:nil];

    [space addWindow:window];
}

- (void)applicationDidFinishLaunching:(NSNotification*)notification {
    [NSApp activateIgnoringOtherApps:false];
}

@end
