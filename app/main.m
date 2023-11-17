#import "AppDelegate.h"
#import "Menu.h"
#import <Cocoa/Cocoa.h>

#import "private_apis/CGSHotKeys.h"  // TODO: temp; move this

int main() {
    @autoreleasepool {
        // TODO: make this work in .mm files so you can move it out of here
        CGSSetSymbolicHotKeyEnabled(commandTab, false);

        NSApplication* app = [NSApplication sharedApplication];
        AppDelegate* appDelegate = [[AppDelegate alloc] init];

        app.activationPolicy = NSApplicationActivationPolicyAccessory;
        app.mainMenu = [[Menu alloc] init];
        app.delegate = appDelegate;

        [app run];
    }
}
