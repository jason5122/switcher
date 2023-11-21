#import "global_switcher_shortcut.h"
#import "private_apis/CGSHotKeys.h"
#import "util/log_util.h"
#import <ShortcutRecorder/ShortcutRecorder.h>
#import <vector>

global_switcher_shortcut::global_switcher_shortcut(WindowController* windowController) {
    this->windowController = windowController;
}

void global_switcher_shortcut::register_hotkey(NSString* shortcutString, std::string action) {
    SRShortcut* shortcut = [SRShortcut shortcutWithKeyEquivalent:shortcutString];
    EventHotKeyID hotKeyId = {signature, global_hotkey_map[action]};
    EventHotKeyRef hotKey;
    OSStatus status =
        RegisterEventHotKey(shortcut.carbonKeyCode, shortcut.carbonModifierFlags, hotKeyId,
                            GetEventDispatcherTarget(), kEventHotKeyNoOptions, &hotKey);
    if (status != noErr) {
        log_with_type(OS_LOG_TYPE_ERROR, [NSString stringWithFormat:@"register fail: %d", status],
                      @"global-switcher-shortcut");
    }
}

void handle_event(EventHotKeyID hotKeyId, global_switcher_shortcut* handler, bool is_pressed) {
    std::string state = is_pressed ? "pressed" : "released";

    if (hotKeyId.id == 0) {
        log_with_type(OS_LOG_TYPE_DEFAULT, "nextWindowShortcut " + state,
                      @"global-switcher-shortcut");
        [handler->windowController setupWindowAndSpace];
    } else if (hotKeyId.id == 2) {
        log_with_type(OS_LOG_TYPE_DEFAULT, "cancelShortcut " + state, @"global-switcher-shortcut");
    }
}

void global_switcher_shortcut::add_global_handler() {
    std::vector<EventTypeSpec> event_types_pressed = {{kEventClassKeyboard, kEventHotKeyPressed}};
    InstallEventHandler(
        GetEventDispatcherTarget(),
        [](EventHandlerCallRef inHandler, EventRef inEvent, void* inUserData) -> OSStatus {
            EventHotKeyID hotKeyId;
            GetEventParameter(inEvent, kEventParamDirectObject, typeEventHotKeyID, nil,
                              sizeof(EventHotKeyID), nil, &hotKeyId);
            global_switcher_shortcut* handler = (global_switcher_shortcut*)inUserData;
            handle_event(hotKeyId, handler, true);
            return noErr;
        },
        event_types_pressed.size(), &event_types_pressed[0], this, &hotkey_pressed_handler);

    std::vector<EventTypeSpec> event_types_released = {
        {kEventClassKeyboard, kEventHotKeyReleased}};
    InstallEventHandler(
        GetEventDispatcherTarget(),
        [](EventHandlerCallRef inHandler, EventRef inEvent, void* inUserData) -> OSStatus {
            EventHotKeyID hotKeyId;
            GetEventParameter(inEvent, kEventParamDirectObject, typeEventHotKeyID, nil,
                              sizeof(EventHotKeyID), nil, &hotKeyId);
            global_switcher_shortcut* handler = (global_switcher_shortcut*)inUserData;
            handle_event(hotKeyId, handler, false);
            return noErr;
        },
        event_types_released.size(), &event_types_released[0], this, &hotkey_released_handler);
}

void global_switcher_shortcut::set_native_command_tab_enabled(bool is_enabled) {
    CGSSetSymbolicHotKeyEnabled(commandTab, is_enabled);
}

global_switcher_shortcut::~global_switcher_shortcut() {
    RemoveEventHandler(hotkey_pressed_handler);
    RemoveEventHandler(hotkey_released_handler);
}
