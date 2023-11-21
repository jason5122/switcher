#import "AppDelegate.h"
#import "Menu.h"
#import "model/global_switcher_shortcut.h"
#import <Cocoa/Cocoa.h>

int main() {
    signal(SIGTERM, [](int sig) {
        global_switcher_shortcut::set_native_command_tab_enabled(true);
        exit(0);
    });

    @autoreleasepool {
        NSApplication* app = [NSApplication sharedApplication];
        AppDelegate* appDelegate = [[AppDelegate alloc] init];

        app.activationPolicy = NSApplicationActivationPolicyAccessory;
        app.mainMenu = [[Menu alloc] init];
        app.delegate = appDelegate;

        [app run];
    }
}
