#import "AppDelegate.h"

@implementation AppDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        CGSize size = CGSizeMake(280, 175);
        CGFloat padding = 20;
        CGFloat innerPadding = 15;

        windowController = [[WindowController alloc] initWithSize:size
                                                          padding:padding
                                                     innerPadding:innerPadding];
        sh_manager = new shortcut_manager(windowController);
    }
    return self;
}

- (void)applicationWillFinishLaunching:(NSNotification*)notification {
    shortcut_manager::set_native_command_tab_enabled(false);
    sh_manager->register_hotkey(@"⌘⇥", "nextWindowShortcut");
    sh_manager->register_hotkey(@"⌘", "holdShortcut");
    sh_manager->add_global_handler();
    sh_manager->add_modifier_event_tap();
}

- (void)applicationWillTerminate:(NSNotification*)notification {
    sh_manager->set_native_command_tab_enabled(true);
}

@end
