#import "AppDelegate.h"
#import "controller/WindowController.h"
#import "model/shortcut_manager.h"

struct CppMembers {
    shortcut_manager* switcher_shortcut;
};

@implementation AppDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        cpp = new CppMembers;

        windowController = [[WindowController alloc] init];
        cpp->switcher_shortcut = new shortcut_manager(windowController);
    }
    return self;
}

- (void)applicationWillFinishLaunching:(NSNotification*)notification {
    shortcut_manager::set_native_command_tab_enabled(false);
    cpp->switcher_shortcut->register_hotkey(@"⌘⇥", "nextWindowShortcut");
    cpp->switcher_shortcut->register_hotkey(@"⌘", "holdShortcut");
    cpp->switcher_shortcut->add_global_handler();
    cpp->switcher_shortcut->add_modifier_event_tap();
}

- (void)applicationWillTerminate:(NSNotification*)notification {
    cpp->switcher_shortcut->set_native_command_tab_enabled(true);
}

@end
