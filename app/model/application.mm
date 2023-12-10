#import "application.h"
#import "private_apis/AXUI.h"
#import "util/log_util.h"

application::application(pid_t pid) {
    this->pid = pid;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    GetProcessForPID(pid, &psn);
#pragma clang diagnostic pop

    axUiElement = AXUIElementCreateApplication(pid);
}

bool application::is_xpc() {
    ProcessInfoRec info = ProcessInfoRec();
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    GetProcessInformation(&psn, &info);
#pragma clang diagnostic pop
    return info.processType == 'XPC!';
}

void application::populate_initial_windows() {
    CFArrayRef windowList;
    AXError err =
        AXUIElementCopyAttributeValue(axUiElement, kAXWindowsAttribute, (CFTypeRef*)&windowList);

    if (err == kAXErrorSuccess) {
        for (int i = 0; i < CFArrayGetCount(windowList); i++) {
            AXUIElementRef windowRef = (AXUIElementRef)CFArrayGetValueAtIndex(windowList, i);
            windows.push_back(windowRef);
        }
    }
}
