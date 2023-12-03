#import "controller/WindowController.h"
#import "controller/shortcut_controller.h"
#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    WindowController* windowController;
    shortcut_controller* sh_controller;
    NSStatusItem* statusBarItem;
}

@end
