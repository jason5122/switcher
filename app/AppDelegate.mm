#import "AppDelegate.h"

@implementation AppDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        // CGSize size = CGSizeMake(280, 175);
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

@end
