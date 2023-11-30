#import "AppDelegate.h"
#import "Menu.h"
#import "controller/shortcut_controller.h"
#import "util/log_util.h"
#import <Cocoa/Cocoa.h>

int main() {
    signal(SIGTERM, [](int sig) {
        shortcut_controller::set_native_command_tab_enabled(true);
        exit(0);
    });

    NSSetUncaughtExceptionHandler([](NSException* exception) {
        custom_log(OS_LOG_TYPE_ERROR, @"main", @"%@ %@", exception.name, exception.reason);
    });

    @autoreleasepool {
        NSApplication* app = [NSApplication sharedApplication];
        AppDelegate* appDelegate = [[AppDelegate alloc] init];

        app.activationPolicy = NSApplicationActivationPolicyRegular;
        // app.activationPolicy = NSApplicationActivationPolicyAccessory;
        app.mainMenu = [[Menu alloc] init];
        app.delegate = appDelegate;

        [app run];
    }
}
