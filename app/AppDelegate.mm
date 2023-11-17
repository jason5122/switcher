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

        SRShortcut* shortcut = [SRShortcut shortcutWithKeyEquivalent:@"⇧⌘B"];
        _cppMembers->switcher_shortcut = new global_switcher_shortcut(shortcut);
    }
    return self;
}

- (void)applicationWillFinishLaunching:(NSNotification*)notification {
    [windowController setupWindowAndSpace];
    _cppMembers->switcher_shortcut->register_hotkey();
    _cppMembers->switcher_shortcut->add_global_handler();
    _cppMembers->switcher_shortcut->register_for_getting_hotkey_events();
    // TODO: disable command-tab
}

- (void)applicationDidFinishLaunching:(NSNotification*)notification {
    [NSApp activateIgnoringOtherApps:false];
}

- (void)windowWillClose:(NSNotification*)notification {
    _cppMembers->switcher_shortcut->unregister_for_getting_hotkey_events();
    // TODO: re-enable command-tab
}

@end
