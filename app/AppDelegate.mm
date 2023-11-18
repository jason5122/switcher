#import "AppDelegate.h"
#import "controller/WindowController.h"
#import "model/global_switcher_shortcut.h"
#import <ShortcutRecorder/ShortcutRecorder.h>

struct CppMembers {
    global_switcher_shortcut* switcher_shortcut;
};

@implementation AppDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        _cppMembers = new CppMembers;

        windowController = [[WindowController alloc] init];

        SRShortcut* shortcut = [SRShortcut shortcutWithKeyEquivalent:@"⌘⇥"];
        _cppMembers->switcher_shortcut = new global_switcher_shortcut(shortcut, windowController);
    }
    return self;
}

- (void)applicationWillFinishLaunching:(NSNotification*)notification {
    // [windowController setupWindowAndSpace];
    _cppMembers->switcher_shortcut->set_command_tab_enabled(false);
    _cppMembers->switcher_shortcut->register_hotkey();
    _cppMembers->switcher_shortcut->add_global_handler();
    _cppMembers->switcher_shortcut->register_for_getting_hotkey_events();
}

- (void)applicationDidFinishLaunching:(NSNotification*)notification {
    // [NSApp activateIgnoringOtherApps:false];
}

- (void)applicationWillTerminate:(NSNotification*)notification {
    _cppMembers->switcher_shortcut->unregister_for_getting_hotkey_events();
    _cppMembers->switcher_shortcut->set_command_tab_enabled(true);
}

@end
