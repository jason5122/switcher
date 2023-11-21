#import "controller/WindowController.h"
#import <Carbon/Carbon.h>
#import <string>
#import <unordered_map>

class global_switcher_shortcut {
public:
    WindowController* windowController;

    global_switcher_shortcut(WindowController* windowController);
    ~global_switcher_shortcut();
    void register_hotkey(NSString* shortcutString, std::string action);
    void add_global_handler();
    static void set_native_command_tab_enabled(bool is_enabled);

private:
    EventHandlerRef hotkey_pressed_handler;
    EventHandlerRef hotkey_released_handler;

    FourCharCode signature = (FourCharCode)'1234';  // TODO: change to something else
    std::unordered_map<std::string, UInt32> hotkeyid_map = {
        {"nextWindowShortcut", 0},
        {"holdShortcut", 1},
        {"cancelShortcut", 2},
    };
};
