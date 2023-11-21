#import "AppDelegate.h"
#import "Menu.h"
#import "private_apis/CGSHotKeys.h"
#import <Cocoa/Cocoa.h>

int main() {
    signal(SIGTERM, [](int sig) {
        CGSSetSymbolicHotKeyEnabled(commandTab, true);
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
