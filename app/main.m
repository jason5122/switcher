#include "AppDelegate.h"
#include <Cocoa/Cocoa.h>

int main() {
    @autoreleasepool {
        NSApplication* application = [NSApplication sharedApplication];

        AppDelegate* appDelegate = [[AppDelegate alloc] init];

        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
        [NSApp activateIgnoringOtherApps:YES];

        [application setDelegate:appDelegate];
        [application run];
    }
}
