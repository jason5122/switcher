#import "AppDelegate.h"
#import "view/OpenGLView.h"

@implementation AppDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        space = [[CGSSpace alloc] initWithLevel:1];

        int mask = NSWindowStyleMaskFullSizeContentView;
        window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 425, 182)
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

        // window.contentView = visualEffect;

        window.contentView = [[OpenGLView alloc] initWithFrame:NSMakeRect(0, 0, 425, 182)];
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
