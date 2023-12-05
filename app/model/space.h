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
    static std::vector<CGWindowID>
    get_all_valid_window_ids(std::unordered_map<CGWindowID, window_element>& window_map);
    static std::vector<CGWindowID> get_all_window_ids_new();
    static std::vector<CGWindowID> get_all_window_ids();
};
