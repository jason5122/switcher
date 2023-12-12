#import "applications.h"
#import "extensions/AXUIElement.h"
#import "extensions/CGWindow.h"
#import "model/space.h"
#import "util/log_util.h"

void applications::debug_print() {
    custom_log(OS_LOG_TYPE_DEFAULT, @"applications",
               @"app_map: %d window_map: %d window_ref_map: %d", app_map.size(), window_map.size(),
               window_ref_map.size());
}

applications::applications() {
    NSNotificationCenter* notifCenter = NSWorkspace.sharedWorkspace.notificationCenter;
    [notifCenter addObserverForName:NSWorkspaceDidLaunchApplicationNotification
                             object:nil
                              queue:NSOperationQueue.mainQueue
                         usingBlock:^(NSNotification* notification) {
                           NSRunningApplication* runningApp =
                               notification.userInfo[@"NSWorkspaceApplicationKey"];
                           add_app(runningApp.processIdentifier);
                           custom_log(OS_LOG_TYPE_DEFAULT, @"applications", @"added pid: %d",
                                      runningApp.processIdentifier);
                           debug_print();
                         }];
    [notifCenter addObserverForName:NSWorkspaceDidTerminateApplicationNotification
                             object:nil
                              queue:NSOperationQueue.mainQueue
                         usingBlock:^(NSNotification* notification) {
                           NSRunningApplication* runningApp =
                               notification.userInfo[@"NSWorkspaceApplicationKey"];
                           remove_app(runningApp.processIdentifier);
                           custom_log(OS_LOG_TYPE_DEFAULT, @"applications", @"removed pid: %d",
                                      runningApp.processIdentifier);
                           debug_print();
                         }];
}

void applications::detect_new_apps() {
    for (CGWindowID wid : CGWindowListIDs()) {
        pid_t pid;

        CGSConnectionID elementConnection;
        CGSGetWindowOwner(CGSMainConnectionID(), wid, &elementConnection);
        ProcessSerialNumber psn = ProcessSerialNumber();
        CGSGetConnectionPSN(elementConnection, &psn);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        GetProcessPID(&psn, &pid);
#pragma clang diagnostic pop

        add_app(pid);
    }

    debug_print();
}

void applications::refresh_app_window_ids() {
    for (auto& [pid, app] : app_map) {
        for (AXUIElementRef& windowRef : AXUIElementGetWindows(app.axRef)) {
            add_window_ref(windowRef);
        }
    }

    debug_print();
}

std::vector<CGWindowID> applications::get_valid_window_ids(bool active_app_only) {
    std::vector<CGWindowID> result;
    pid_t frontmost_pid = NSWorkspace.sharedWorkspace.frontmostApplication.processIdentifier;
    for (CGWindowID wid : CGWindowListIDs()) {
        if (window_map.count(wid)) {
            pid_t pid;
            AXUIElementGetPid(window_map[wid].windowRef, &pid);
            if (active_app_only && pid != frontmost_pid) continue;

            if (AXUIElementIsValidWindow(window_map[wid].windowRef)) {
                result.push_back(wid);
            }
        }
    }
    return result;
}

void applications::add_app(pid_t pid) {
    application app = application(pid);
    if (app_map.count(pid)) return;
    if (app.is_xpc()) return;

    app_map[pid] = app;
    add_observer(app);

    for (AXUIElementRef& windowRef : AXUIElementGetWindows(app.axRef)) {
        add_window_ref(windowRef);
    }
}

void applications::remove_app(pid_t pid) {
    if (!app_map.count(pid)) return;
    app_map.erase(pid);
}

void applications::add_window_ref(AXUIElementRef windowRef) {
    window_element win_el = window_element(windowRef);
    window_map[win_el.wid] = win_el;
    window_ref_map[CFHash(windowRef)] = win_el.wid;
}

void applications::remove_window_ref(AXUIElementRef windowRef) {
    window_map.erase(window_ref_map[CFHash(windowRef)]);
    window_ref_map.erase(CFHash(windowRef));
}

void observer_callback(AXObserverRef observer, AXUIElementRef windowRef,
                       CFStringRef notificationName, void* inUserData) {
    applications* apps = (applications*)inUserData;
    if (CFEqual(notificationName, kAXWindowCreatedNotification)) {
        if (AXUIElementIsValidWindow(windowRef)) {
            apps->add_window_ref((AXUIElementRef)CFRetain(windowRef));
        }
    } else if (CFEqual(notificationName, kAXUIElementDestroyedNotification)) {
        apps->remove_window_ref(windowRef);
    }
}

void applications::add_observer(application& app) {
    AXObserverRef axObserver;

    /*
     * WARNING: Starting SCStream triggers kAXWindowCreatedNotification (one per captured window).
     * This is due to the Sonoma screen recording icon counting as a window.
     */
    AXObserverCreate(app.pid, &observer_callback, &axObserver);

    AXObserverAddNotification(axObserver, app.axRef, kAXWindowCreatedNotification, this);
    AXObserverAddNotification(axObserver, app.axRef, kAXUIElementDestroyedNotification, this);
    CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(axObserver),
                       kCFRunLoopDefaultMode);
}
