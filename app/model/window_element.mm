#import "private_apis/AXUI.h"
#import "private_apis/SkyLight.h"
#import "window_element.h"

window_element::window_element() {}

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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
      // https://github.com/koekeishiya/yabai/issues/1772#issuecomment-1649919480
      _SLPSSetFrontProcessWithOptions(&psn, 0, kSLPSNoWindows);
      AXUIElementPerformAction(windowRef, kAXRaiseAction);
    });
}
