#import "AppDelegate.h"
#import "controller/WindowController.h"
#import "model/global_switcher_shortcut.h"

struct CppMembers {
    global_switcher_shortcut* switcher_shortcut;
};

@implementation AppDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        _cppMembers = new CppMembers;

        windowController = [[WindowController alloc] init];
        _cppMembers->switcher_shortcut = new global_switcher_shortcut(windowController);
    }
    return self;
}

- (void)applicationWillFinishLaunching:(NSNotification*)notification {
    global_switcher_shortcut::set_native_command_tab_enabled(false);
    _cppMembers->switcher_shortcut->register_hotkey(@"⌘⇥", "nextWindowShortcut");
    _cppMembers->switcher_shortcut->register_hotkey(@"⌘", "holdShortcut");
    _cppMembers->switcher_shortcut->add_global_handler();
    _cppMembers->switcher_shortcut->add_modifier_event_tap();
}

- (void)applicationWillTerminate:(NSNotification*)notification {
    _cppMembers->switcher_shortcut->set_native_command_tab_enabled(true);
}

@end
