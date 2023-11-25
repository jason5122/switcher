#import "controller/WindowController.h"
#import "model/shortcut_manager.h"
#import <Cocoa/Cocoa.h>

struct CppMembers;

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    WindowController* windowController;
    shortcut_manager* switcher_shortcut;
}

@end
