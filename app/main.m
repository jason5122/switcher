#import "AppDelegate.h"
#import "Menu.h"
#import <Cocoa/Cocoa.h>

int main() {
    @autoreleasepool {
        NSApplication* app = [NSApplication sharedApplication];
        AppDelegate* appDelegate = [[AppDelegate alloc] init];

        app.activationPolicy = NSApplicationActivationPolicyRegular;
        app.mainMenu = [[Menu alloc] init];
        app.delegate = appDelegate;

        [app run];
    }
}
