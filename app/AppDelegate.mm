#import "AppDelegate.h"

struct CppMembers {
    shortcut_manager* switcher_shortcut;
};

@implementation AppDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        windowController = [[WindowController alloc] init];
        switcher_shortcut = new shortcut_manager(windowController);
    }
    return self;
}

- (void)applicationWillFinishLaunching:(NSNotification*)notification {
    shortcut_manager::set_native_command_tab_enabled(false);
    switcher_shortcut->register_hotkey(@"⌘⇥", "nextWindowShortcut");
    switcher_shortcut->register_hotkey(@"⌘", "holdShortcut");
    switcher_shortcut->add_global_handler();
    switcher_shortcut->add_modifier_event_tap();
}

- (void)applicationWillTerminate:(NSNotification*)notification {
    switcher_shortcut->set_native_command_tab_enabled(true);
}

@end
