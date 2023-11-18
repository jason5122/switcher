#import "global_switcher_shortcut.h"
#import "private_apis/CGSHotKeys.h"
#import "util/log_util.h"
#import <Carbon/Carbon.h>

struct shortcut_info_t {
    SRShortcut* shortcut;
    EventHandlerRef hotkey_pressed_handler;
    NSWindow* window;
};

static NSString* shortcut_to_string(SRShortcut* shortcut) {
    NSMutableString* result = [[NSMutableString alloc] init];

    if (shortcut.modifierFlags & NSEventModifierFlagControl) [result appendString:@"⇧"];
    if (shortcut.modifierFlags & NSEventModifierFlagOption) [result appendString:@"⇧"];
    if (shortcut.modifierFlags & NSEventModifierFlagShift) [result appendString:@"⇧"];
    if (shortcut.modifierFlags & NSEventModifierFlagCommand) [result appendString:@"⌘"];

    if (shortcut.keyCode == kVK_Tab) [result appendString:@"⇥"];
    else [result appendString:shortcut.charactersIgnoringModifiers];

    return [NSString stringWithString:result];
}

static OSStatus EventHandler(EventHandlerCallRef inHandler, EventRef inEvent, void* inUserData) {
    EventHotKeyID hotKeyID;
    GetEventParameter(inEvent, kEventParamDirectObject, typeEventHotKeyID, nil,
                      sizeof(EventHotKeyID), nil, &hotKeyID);

    // TODO: look up hotkey in array of registered hotkeys
    //       decide handling logic that way

    global_switcher_shortcut* handler = (global_switcher_shortcut*)inUserData;

    log_with_type(OS_LOG_TYPE_DEFAULT, shortcut_to_string(handler->sh->shortcut),
                  @"global-switcher-shortcut");

    [handler->windowController setupWindowAndSpace];

    // return this error for other handlers to handle this event as well
    return eventNotHandledErr;
}

global_switcher_shortcut::global_switcher_shortcut(SRShortcut* shortcut,
                                                   WindowController* windowController) {
    sh = new shortcut_info_t;
    sh->shortcut = shortcut;
    this->windowController = windowController;
}

void global_switcher_shortcut::register_hotkey() {
    FourCharCode signature = (FourCharCode)'1234';
    EventHotKeyID hotKeyID = {signature, 1};
    EventHotKeyRef hotKey;
    OSStatus status =
        RegisterEventHotKey(sh->shortcut.carbonKeyCode, sh->shortcut.carbonModifierFlags, hotKeyID,
                            GetEventDispatcherTarget(), kEventHotKeyNoOptions, &hotKey);
    if (status != noErr) {
        log_with_type(OS_LOG_TYPE_ERROR, [NSString stringWithFormat:@"register fail: %d", status],
                      @"global-switcher-shortcut");
    }
}

void global_switcher_shortcut::add_global_handler() {
    OSStatus status = InstallEventHandler(GetEventDispatcherTarget(), &EventHandler, 0, nil, this,
                                          &sh->hotkey_pressed_handler);
    if (status != noErr) {
        log_with_type(OS_LOG_TYPE_ERROR,
                      [NSString stringWithFormat:@"global handler fail: %d", status],
                      @"global-switcher-shortcut");
    }
}

void global_switcher_shortcut::register_for_getting_hotkey_events() {
    const EventTypeSpec kHotKeysEvent[] = {{kEventClassKeyboard, kEventHotKeyPressed}};
    AddEventTypesToHandler(sh->hotkey_pressed_handler, GetEventTypeCount(kHotKeysEvent),
                           kHotKeysEvent);
}

void global_switcher_shortcut::unregister_for_getting_hotkey_events() {
    const EventTypeSpec kHotKeysEvent[] = {{kEventClassKeyboard, kEventHotKeyPressed}};
    RemoveEventTypesFromHandler(sh->hotkey_pressed_handler, GetEventTypeCount(kHotKeysEvent),
                                kHotKeysEvent);
}

void global_switcher_shortcut::set_command_tab_enabled(bool is_enabled) {
    CGSSetSymbolicHotKeyEnabled(commandTab, is_enabled);
}
