#import "private_apis/SkyLight.h"
#import "window.h"

window::window(pid_t app_pid, AXUIElementRef windowRef) {
    this->app_pid = app_pid;
    this->windowRef = windowRef;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    GetProcessForPID(app_pid, &psn);
#pragma clang diagnostic pop
    _AXUIElementGetWindow(windowRef, &wid);

    // TODO: monitor title updates
    CFStringRef stringRef;
    AXUIElementCopyAttributeValue(windowRef, kAXTitleAttribute, (CFTypeRef*)&stringRef);
    title = (__bridge NSString*)stringRef;
}

void window::focus() {
    // https://github.com/koekeishiya/yabai/issues/1772#issuecomment-1649919480
    _SLPSSetFrontProcessWithOptions(&psn, 0, kSLPSNoWindows);
    AXUIElementPerformAction(windowRef, kAXRaiseAction);
}
