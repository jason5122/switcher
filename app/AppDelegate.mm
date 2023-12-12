#import "AppDelegate.h"
#import "util/log_util.h"

@implementation AppDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        NSDictionary* options = @{(__bridge NSString*)kAXTrustedCheckOptionPrompt : @false};
        bool accessibilityGranted =
            AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
        bool screenRecordingGranted = CGPreflightScreenCaptureAccess();
        if (!accessibilityGranted) {
            custom_log(OS_LOG_TYPE_ERROR, @"app-delegate",
                       @"accessibility permissions not granted");
        }
        if (!screenRecordingGranted) {
            custom_log(OS_LOG_TYPE_ERROR, @"app-delegate",
                       @"screen recording permissions not granted");
        }
        if (!accessibilityGranted || !screenRecordingGranted) {
            [NSApp terminate:nil];
        }

        CGSize size = CGSizeMake(160, 100);
        CGFloat padding = 20;
        CGFloat innerPadding = 15;
        CGFloat titleTextPadding = 15;

        windowController = [[WindowController alloc] initWithSize:size
                                                          padding:padding
                                                     innerPadding:innerPadding
                                                 titleTextPadding:titleTextPadding];
        sh_controller = new shortcut_controller(windowController, @"⎋");
    }
    return self;
}

- (void)applicationWillFinishLaunching:(NSNotification*)notification {
    statusBarItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    statusBarItem.button.image = [NSImage imageWithSystemSymbolName:@"star.fill"
                                           accessibilityDescription:@"Status bar icon"];

    NSString* appName = NSBundle.mainBundle.infoDictionary[@"CFBundleName"];
    NSMenu* statusBarMenu = [[NSMenu alloc] init];
    [statusBarMenu addItemWithTitle:[NSString stringWithFormat:@"About %@", appName]
                             action:@selector(showAboutPanel)
                      keyEquivalent:@""];
    [statusBarMenu addItem:[NSMenuItem separatorItem]];
    [statusBarMenu addItemWithTitle:[NSString stringWithFormat:@"Quit %@", appName]
                             action:@selector(terminate:)
                      keyEquivalent:@"q"];
    statusBarItem.menu = statusBarMenu;

    shortcut_controller::set_native_command_tab_enabled(false);
    sh_controller->register_hotkey(@"⌘⇥", "nextWindowShortcut");
    sh_controller->register_hotkey(@"⌘`", "nextWindowShortcutActiveApp");
    sh_controller->register_hotkey(@"⌘", "holdShortcut");
    sh_controller->add_global_handler();
    sh_controller->add_modifier_event_tap();
}

- (void)applicationWillTerminate:(NSNotification*)notification {
    sh_controller->set_native_command_tab_enabled(true);
}

- (void)showAboutPanel {
    [NSApplication.sharedApplication orderFrontStandardAboutPanel:statusBarItem];
    [NSApplication.sharedApplication activateIgnoringOtherApps:true];
}

@end
