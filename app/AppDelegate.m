#import "AppDelegate.h"
#import "view/OpenGLView.h"
#import <ShortcutRecorder/ShortcutRecorder.h>

@implementation AppDelegate

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

        // ShortcutRecorder test
        NSUserDefaultsController* defaults = NSUserDefaultsController.sharedUserDefaultsController;
        NSString* keyPath = @"values.shortcut";
        NSDictionary* options =
            @{NSValueTransformerNameBindingOption : NSKeyedUnarchiveFromDataTransformerName};

        SRShortcutAction* beepAction =
            [SRShortcutAction shortcutActionWithKeyPath:keyPath
                                               ofObject:defaults
                                          actionHandler:^BOOL(SRShortcutAction* anAction) {
                                            NSBeep();
                                            return YES;
                                          }];
        [[SRGlobalShortcutMonitor sharedMonitor] addAction:beepAction
                                               forKeyEvent:SRKeyEventTypeDown];

        SRRecorderControl* recorder = [SRRecorderControl new];
        [recorder bind:NSValueBinding toObject:defaults withKeyPath:keyPath options:options];

        recorder.objectValue = [SRShortcut shortcutWithKeyEquivalent:@"⇧⌘A"];
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
