#import "private_apis/CGSHotKeys.h"
#import "shortcut_manager.h"
#import "util/log_util.h"
#import <ShortcutRecorder/ShortcutRecorder.h>
#import <vector>

shortcut_manager::shortcut_manager(WindowController* windowController) {
    this->windowController = windowController;
}

void shortcut_manager::register_hotkey(NSString* shortcutString, std::string action) {
    SRShortcut* shortcut = [SRShortcut shortcutWithKeyEquivalent:shortcutString];
    EventHotKeyID hotKeyId = {signature, global_hotkey_map[action]};
    EventHotKeyRef hotKey;
    OSStatus status =
        RegisterEventHotKey(shortcut.carbonKeyCode, shortcut.carbonModifierFlags, hotKeyId,
                            GetEventDispatcherTarget(), kEventHotKeyNoOptions, &hotKey);
    if (status != noErr) {
        log_with_type(OS_LOG_TYPE_ERROR, [NSString stringWithFormat:@"register fail: %d", status],
                      @"shortcut-manager");
    }
}

void handle_event(EventHotKeyID hotKeyId, shortcut_manager* handler, bool is_pressed) {
    if (!is_pressed) return;

    std::string state = is_pressed ? "pressed" : "released";

    if (hotKeyId.id == 0) {
        log_with_type(OS_LOG_TYPE_DEFAULT, "nextWindowShortcut " + state, @"shortcut-manager");
        [handler->windowController showWindow];
    }
}

void shortcut_manager::add_global_handler() {
    std::vector<EventTypeSpec> event_types_pressed = {{kEventClassKeyboard, kEventHotKeyPressed}};
    InstallEventHandler(
        GetEventDispatcherTarget(),
        [](EventHandlerCallRef inHandler, EventRef inEvent, void* inUserData) -> OSStatus {
            EventHotKeyID hotKeyId;
            GetEventParameter(inEvent, kEventParamDirectObject, typeEventHotKeyID, nil,
                              sizeof(EventHotKeyID), nil, &hotKeyId);
            shortcut_manager* handler = (shortcut_manager*)inUserData;
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
            shortcut_manager* handler = (shortcut_manager*)inUserData;
            handle_event(hotKeyId, handler, false);
            return noErr;
        },
        event_types_released.size(), &event_types_released[0], this, &hotkey_released_handler);
}

CGEventRef modifier_callback(CGEventTapProxy proxy, CGEventType type, CGEventRef cgEvent,
                             void* inUserData) {
    shortcut_manager* handler = (shortcut_manager*)inUserData;
    if (type == kCGEventFlagsChanged) {
        NSUInteger flags = CGEventGetFlags(cgEvent);
        if (!(flags & NSEventModifierFlagCommand) && handler->windowController.isShown) {
            log_with_type(OS_LOG_TYPE_DEFAULT, @"⌘ released", @"shortcut-manager");
            [handler->windowController focusSelectedIndex];
            [handler->windowController hideWindow];
        }
    } else if (type == kCGEventKeyDown) {
        CGKeyCode keycode =
            (CGKeyCode)CGEventGetIntegerValueField(cgEvent, kCGKeyboardEventKeycode);
        if (keycode == 53 && handler->windowController.isShown) {
            log_with_type(OS_LOG_TYPE_DEFAULT, @"escape pressed", @"shortcut-manager");
            [handler->windowController hideWindow];
            return nil;
        }
    }
    return cgEvent;
}

void shortcut_manager::add_modifier_event_tap() {
    CGEventMask eventMask = CGEventMaskBit(kCGEventFlagsChanged) | CGEventMaskBit(kCGEventKeyDown);
    CFMachPortRef eventTap =
        CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault,
                         eventMask, modifier_callback, this);
    CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(nil, eventTap, 0);
    CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, kCFRunLoopCommonModes);
}

void shortcut_manager::set_native_command_tab_enabled(bool is_enabled) {
    CGSSetSymbolicHotKeyEnabled(kCGCommandTab, is_enabled);
}

shortcut_manager::~shortcut_manager() {
    RemoveEventHandler(hotkey_pressed_handler);
    RemoveEventHandler(hotkey_released_handler);
}
