#import "private_apis/CGSSpace.h"
#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow* window;

@private
    CGSSpace* space;
}

@end
