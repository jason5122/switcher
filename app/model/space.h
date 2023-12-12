#import "model/window_element.h"
#import "private_apis/CGS.h"
#import <Cocoa/Cocoa.h>
#import <unordered_map>
#import <vector>

class space {
    CGSSpaceID spaceId;

public:
    space(int level);
    ~space();
    void add_window(NSWindow* window);
};
