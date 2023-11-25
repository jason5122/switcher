#import "application.h"
#import "private_apis/Accessiblity.h"
#import "util/log_util.h"

application::application(NSRunningApplication* runningApp) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    GetProcessForPID(runningApp.processIdentifier, &psn);
#pragma clang diagnostic pop

    this->runningApp = runningApp;
    this->axUiElement = AXUIElementCreateApplication(runningApp.processIdentifier);
}

NSString* application::localizedName() {
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
    AXUIElementCopyAttributeValue(axUiElement, kAXWindowsAttribute, (CFTypeRef*)&windowList);
    for (int i = 0; i < CFArrayGetCount(windowList); i++) {
        AXUIElementRef windowRef = (AXUIElementRef)CFArrayGetValueAtIndex(windowList, i);

        // TODO: handle minimized windows better
        CFBooleanRef minimizedRef;
        AXUIElementCopyAttributeValue(windowRef, kAXMinimizedAttribute, (CFTypeRef*)&minimizedRef);
        bool is_minimized = CFBooleanGetValue(minimizedRef);
        if (!is_minimized) windows.push_back(window(runningApp.processIdentifier, windowRef));
    }
}

void application::append_windows(std::vector<window>& windows) {
    windows.insert(windows.end(), this->windows.begin(), this->windows.end());
}

void application::add_observer() {
    AXObserverRef axObserver;

    // WARNING: starting SCStream triggers kAXWindowCreatedNotification (one per captured window)
    AXObserverCreate(
        runningApp.processIdentifier,
        [](AXObserverRef observer, AXUIElementRef element, CFStringRef notificationName,
           void* refCon) {
            CGWindowID wid = CGWindowID();
            _AXUIElementGetWindow(element, &wid);
            if (CFEqual(notificationName, kAXWindowCreatedNotification)) {
                log_with_type(OS_LOG_TYPE_DEFAULT,
                              [NSString stringWithFormat:@"window created: %d", wid],
                              @"application");
            }
        },
        &axObserver);
    AXObserverAddNotification(axObserver, axUiElement, kAXWindowCreatedNotification, nil);
    CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(axObserver),
                       kCFRunLoopDefaultMode);
}
