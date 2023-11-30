#import "private_apis/CGS.h"
#import <Cocoa/Cocoa.h>
#import <vector>

@interface Space : NSObject {
    CGSSpaceID identifier;
}

- (instancetype)initWithLevel:(int)level;

- (void)addWindow:(NSWindow*)window;

+ (std::vector<CGWindowID>)getAllWindowIds;

@end
