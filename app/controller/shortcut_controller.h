#import "controller/WindowController.h"
#import <Carbon/Carbon.h>
#import <ShortcutRecorder/ShortcutRecorder.h>
#import <string>
#import <unordered_map>

class shortcut_controller {
public:
    WindowController* windowController;
    SRShortcut* cancelKey;

    shortcut_controller(WindowController* windowController, NSString* cancelKeyString);
    ~shortcut_controller();
    void register_hotkey(NSString* shortcutString, std::string action);
    void add_global_handler();
    void add_modifier_event_tap();
    static void set_native_command_tab_enabled(bool is_enabled);

private:
    EventHandlerRef hotkey_pressed_handler;
    EventHandlerRef hotkey_released_handler;

    FourCharCode signature = (FourCharCode)'1234';  // TODO: Change to something else.
    std::unordered_map<std::string, UInt32> global_hotkey_map = {
        {"nextWindowShortcut", 0},
        {"nextWindowShortcutActiveApp", 1},
        {"holdShortcut", 2},
    };
};
