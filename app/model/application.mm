#import "application.h"
#import "private_apis/AXUI.h"
#import "util/log_util.h"

application::application(NSRunningApplication* runningApp) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    GetProcessForPID(runningApp.processIdentifier, &psn);
#pragma clang diagnostic pop

    this->runningApp = runningApp;
    this->axUiElement = AXUIElementCreateApplication(runningApp.processIdentifier);
}

NSString* application::name() {
    return runningApp.localizedName;
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

            // TODO: handle minimized windows better
            CFBooleanRef minimizedRef;
            AXUIElementCopyAttributeValue(windowRef, kAXMinimizedAttribute,
                                          (CFTypeRef*)&minimizedRef);
            bool is_minimized = CFBooleanGetValue(minimizedRef);
            if (!is_minimized) {
                windows.push_back(windowRef);
            }
        }
    }
}
