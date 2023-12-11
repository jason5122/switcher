#import "private_apis/CGS.h"
#import "shortcut_controller.h"
#import "util/log_util.h"
#import <vector>

shortcut_controller::shortcut_controller(WindowController* windowController,
                                         NSString* cancelKeyString) {
    this->windowController = windowController;
    cancelKey = [SRShortcut shortcutWithKeyEquivalent:cancelKeyString];
}

void shortcut_controller::register_hotkey(NSString* shortcutString, std::string action) {
    SRShortcut* shortcut = [SRShortcut shortcutWithKeyEquivalent:shortcutString];
    EventHotKeyID hotKeyId = {signature, global_hotkey_map[action]};
    EventHotKeyRef hotKey;
    OSStatus status =
        RegisterEventHotKey(shortcut.carbonKeyCode, shortcut.carbonModifierFlags, hotKeyId,
                            GetEventDispatcherTarget(), kEventHotKeyNoOptions, &hotKey);
    if (status != noErr) {
        custom_log(OS_LOG_TYPE_ERROR, @"shortcut-manager", @"register fail: %d", status);
    }
}

void handle_event(EventHotKeyID hotKeyId, shortcut_controller* handler, bool is_pressed) {
    if (!is_pressed) return;

    if (hotKeyId.id == 0) {
        [handler->windowController showWindow:false];
        [handler->windowController cycleSelectedIndex];
    } else if (hotKeyId.id == 1) {
        [handler->windowController showWindow:true];
        [handler->windowController cycleSelectedIndex];
    }
}

void shortcut_controller::add_global_handler() {
    std::vector<EventTypeSpec> event_types_pressed = {{kEventClassKeyboard, kEventHotKeyPressed}};
    InstallEventHandler(
        GetEventDispatcherTarget(),
        [](EventHandlerCallRef inHandler, EventRef inEvent, void* inUserData) -> OSStatus {
            EventHotKeyID hotKeyId;
            GetEventParameter(inEvent, kEventParamDirectObject, typeEventHotKeyID, nil,
                              sizeof(EventHotKeyID), nil, &hotKeyId);
            shortcut_controller* handler = (shortcut_controller*)inUserData;
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
            shortcut_controller* handler = (shortcut_controller*)inUserData;
            handle_event(hotKeyId, handler, false);
            return noErr;
        },
        event_types_released.size(), &event_types_released[0], this, &hotkey_released_handler);
}

CGEventRef modifier_callback(CGEventTapProxy proxy, CGEventType type, CGEventRef cgEvent,
                             void* inUserData) {
    shortcut_controller* handler = (shortcut_controller*)inUserData;
    if (type == kCGEventFlagsChanged) {
        NSUInteger flags = CGEventGetFlags(cgEvent);
        if (!(flags & NSEventModifierFlagCommand) && handler->windowController.shown) {
            [handler->windowController focusSelectedIndex];
            [handler->windowController hideWindow];
        }
    } else if (type == kCGEventKeyDown) {
        CGKeyCode keycode =
            (CGKeyCode)CGEventGetIntegerValueField(cgEvent, kCGKeyboardEventKeycode);
        if (keycode == handler->cancelKey.carbonKeyCode && handler->windowController.shown) {
            [handler->windowController hideWindow];
            return nil;
        }
    }
    return cgEvent;
}

void shortcut_controller::add_modifier_event_tap() {
    CGEventMask eventMask = CGEventMaskBit(kCGEventFlagsChanged) | CGEventMaskBit(kCGEventKeyDown);
    CFMachPortRef eventTap =
        CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault,
                         eventMask, modifier_callback, this);
    CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(nil, eventTap, 0);
    CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, kCFRunLoopCommonModes);
}

void shortcut_controller::set_native_command_tab_enabled(bool is_enabled) {
    CGSSetSymbolicHotKeyEnabled(kCGCommandTab, is_enabled);
    CGSSetSymbolicHotKeyEnabled(kCGCommandShiftTab, is_enabled);
}

shortcut_controller::~shortcut_controller() {
    RemoveEventHandler(hotkey_pressed_handler);
    RemoveEventHandler(hotkey_released_handler);
}
