#import "controller/WindowController.h"
#import "model/shortcut_manager.h"
#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    WindowController* windowController;
    shortcut_manager* sh_manager;
}

@end
