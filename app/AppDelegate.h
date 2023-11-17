#import "controller/WindowController.h"
#import <Cocoa/Cocoa.h>

struct CppMembers;

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    struct CppMembers* _cppMembers;
    WindowController* windowController;
}

@end
