#import "AppDelegate.h"
#import "Menu.h"
#import "controller/view_controller.h"

@implementation AppDelegate

- (IBAction)newDocument:(id)sender {
    if (windowController == nil) {
        NSSize size = [[NSScreen mainScreen] frame].size;
        CGRect contentSize = CGRectMake(0, 0, size.width, size.height);
        windowController = [[WindowController alloc] initWithBounds:contentSize];
        ViewController* viewController = [[ViewController alloc] initWithBounds:contentSize];
        windowController.contentViewController = viewController;
    }
    [windowController showWindow:nil];
}

- (void)applicationWillFinishLaunching:(NSNotification*)notification {
    NSMenu* mainMenu = [[Menu alloc] createMenu];
    [NSApp setMainMenu:mainMenu];
}

- (void)applicationDidFinishLaunching:(NSNotification*)notification {
    [self newDocument:self];
}

- (BOOL)validateMenuItem:(NSMenuItem*)theMenuItem {
    BOOL enable = [self respondsToSelector:[theMenuItem action]];

    // disable "New" if the window is already up
    if ([theMenuItem action] == @selector(newDocument:)) {
        if ([[windowController window] isKeyWindow]) {
            enable = NO;
        }
    }
    return enable;
}

@end
