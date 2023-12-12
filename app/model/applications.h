#import "model/application.h"
#import "model/window_element.h"
#import <Cocoa/Cocoa.h>
#import <unordered_map>

class applications {
public:
    std::unordered_map<CGWindowID, window_element> window_map;
    std::unordered_map<CFHashCode, CGWindowID> window_ref_map;

    applications();
    void detect_new_apps();
    void refresh_app_window_ids();
    std::vector<CGWindowID> get_valid_window_ids(bool active_app_only);
    void add_window_ref(AXUIElementRef windowRef);
    void remove_window_ref(AXUIElementRef windowRef);

private:
    void debug_print();

    std::unordered_map<pid_t, application> app_map;

    void add_app(pid_t pid);
    void remove_app(pid_t pid);
    void add_observer(application& app);
};
