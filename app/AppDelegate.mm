#import "AppDelegate.h"
#import "private_apis/CGSHotKeys.h"
#import "util/log_util.h"
#import "view/OpenGLView.h"
#import <Carbon/Carbon.h>
#import <ShortcutRecorder/ShortcutRecorder.h>

EventHandlerRef hotKeyPressedEventHandler = nil;

OSStatus EventHandler(EventHandlerCallRef inHandler, EventRef inEvent, void* inUserData) {
    EventHotKeyID hotKeyID;
    GetEventParameter(inEvent, kEventParamDirectObject, typeEventHotKeyID, nil,
                      sizeof(EventHotKeyID), nil, &hotKeyID);

    // use this to get your MyOwnEventHandler object back if need be
    // the reason why we get this is because we passed self in InstallEventHandler
    // in Carbon event callbacks you cannot access self directly
    // because this is a C callback, not an objective C method
    AppDelegate* handler = (__bridge AppDelegate*)inUserData;

    // handle the hotkey here - I usually store the id of the EventHotKeyID struct
    // in a objective C hotkey object to look up events in an array of registered hotkeys
    log_with_type(OS_LOG_TYPE_DEFAULT, @"HEY GUYS", @"app-delegate");

    return eventNotHandledErr;  // return this error for other handlers to handle this event as
                                // well
}

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
        // CGSSetSymbolicHotKeyEnabled(commandTab, false);

        SRShortcut* shortcut = [SRShortcut shortcutWithKeyEquivalent:@"⇧⌘B"];

        log_with_type(OS_LOG_TYPE_DEFAULT, [NSString stringWithFormat:@"%d", shortcut.keyCode],
                      @"app-delegate");

        [self addGlobalHandlerWithShortcut:shortcut];
        [self registerHotKeyWithShortcut:shortcut];

        [self registerForGettingHotKeyEvents];
    }
    return self;
}

- (void)applicationWillFinishLaunching:(NSNotification*)notification {
    [window center];
    [window setFrameAutosaveName:@"switcher"];
    [window makeKeyAndOrderFront:nil];

    [space addWindow:window];
}

- (void)registerHotKeyWithShortcut:(SRShortcut*)shortcut {
    FourCharCode signature = (FourCharCode)'1234';

    UInt32 keyCode = shortcut.carbonKeyCode;
    UInt32 mods = shortcut.carbonModifierFlags;
    EventHotKeyID hotKeyID = {signature, 1};
    EventHotKeyRef hotKey;
    OSStatus status = RegisterEventHotKey(keyCode, mods, hotKeyID, GetEventDispatcherTarget(),
                                          kEventHotKeyNoOptions, &hotKey);
    if (status == noErr) {
        log_with_type(OS_LOG_TYPE_DEFAULT, @"register success", @"app-delegate");
    } else {
        log_with_type(OS_LOG_TYPE_DEFAULT,
                      [NSString stringWithFormat:@"register fail: %d", status], @"app-delegate");
    }
}

- (void)addGlobalHandlerWithShortcut:(SRShortcut*)shortcut {
    EventTypeSpec eventType;
    eventType.eventClass = kEventClassKeyboard;
    eventType.eventKind = kEventHotKeyReleased;

    // OSStatus status =
    //     InstallEventHandler(GetEventDispatcherTarget(),
    //     NewEventHandlerUPP(HotKeyEventHandlerProc),
    //                         1, eventType, nil, &hotKeyPressedEventHandler);
    OSStatus status = InstallEventHandler(GetEventDispatcherTarget(), &EventHandler, 0, nil,
                                          (__bridge void*)self, &hotKeyPressedEventHandler);

    if (status == noErr) {
        log_with_type(OS_LOG_TYPE_DEFAULT, @"global handler success", @"app-delegate");
    } else {
        log_with_type(OS_LOG_TYPE_DEFAULT,
                      [NSString stringWithFormat:@"global handler fail: %d", status],
                      @"app-delegate");
    }
}

// call this objective C wrapper method to register your Carbon Event handler
- (void)registerForGettingHotKeyEvents {
    const EventTypeSpec kHotKeysEvent[] = {{kEventClassKeyboard, kEventHotKeyPressed}};
    AddEventTypesToHandler(hotKeyPressedEventHandler, GetEventTypeCount(kHotKeysEvent),
                           kHotKeysEvent);
}

// call this objective C wrapper method to unregister your Carbon Event handler
- (void)unregisterFromGettingHotKeyEvents {
    const EventTypeSpec kHotKeysEvent[] = {{kEventClassKeyboard, kEventHotKeyPressed}};
    RemoveEventTypesFromHandler(hotKeyPressedEventHandler, GetEventTypeCount(kHotKeysEvent),
                                kHotKeysEvent);
}

- (void)applicationDidFinishLaunching:(NSNotification*)notification {
    [NSApp activateIgnoringOtherApps:false];
}

@end
