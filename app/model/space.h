#import "private_apis/CGS.h"
#import <Cocoa/Cocoa.h>
#import <vector>

class space {
    CGSSpaceID spaceId;

public:
    space(int level);
    ~space();
    void add_window(NSWindow* window);
    static std::vector<CGWindowID> get_all_window_ids_new();
    static std::vector<CGWindowID> get_all_window_ids();
};
