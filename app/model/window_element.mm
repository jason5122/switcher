#import "private_apis/SkyLight.h"
#import "window_element.h"

window_element::window_element() {}  // TODO: maybe remove this in the future

// window_element::window_element(pid_t pid, AXUIElementRef windowRef, NSImage* icon) {
//     this->windowRef = windowRef;
// #pragma clang diagnostic push
// #pragma clang diagnostic ignored "-Wdeprecated-declarations"
//     GetProcessForPID(pid, &psn);
// #pragma clang diagnostic pop
//     _AXUIElementGetWindow(windowRef, &wid);
//     this->icon = icon;

//     // TODO: monitor title updates
//     CFStringRef stringRef;
//     AXUIElementCopyAttributeValue(windowRef, kAXTitleAttribute, (CFTypeRef*)&stringRef);
//     title = (__bridge NSString*)stringRef;
// }

window_element::window_element(AXUIElementRef windowRef) {
    this->windowRef = windowRef;
    pid_t pid;
    AXUIElementGetPid(windowRef, &pid);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    GetProcessForPID(pid, &psn);
#pragma clang diagnostic pop
    _AXUIElementGetWindow(windowRef, &wid);
}

void window_element::focus() {
    // https://github.com/koekeishiya/yabai/issues/1772#issuecomment-1649919480
    _SLPSSetFrontProcessWithOptions(&psn, 0, kSLPSNoWindows);
    AXUIElementPerformAction(windowRef, kAXRaiseAction);
}
