#import "applications.h"
#import "model/space.h"
#import "util/log_util.h"
#import <unordered_set>

applications::applications() {
    NSNotificationCenter* notifCenter = NSWorkspace.sharedWorkspace.notificationCenter;
    [notifCenter addObserverForName:NSWorkspaceDidLaunchApplicationNotification
                             object:nil
                              queue:NSOperationQueue.mainQueue
                         usingBlock:^(NSNotification* notification) {
                           NSRunningApplication* runningApp =
                               notification.userInfo[@"NSWorkspaceApplicationKey"];
                           add_app(runningApp.processIdentifier);
                         }];

    [notifCenter addObserverForName:NSWorkspaceActiveSpaceDidChangeNotification
                             object:nil
                              queue:NSOperationQueue.mainQueue
                         usingBlock:^(NSNotification* notification) {
                           custom_log(OS_LOG_TYPE_DEFAULT, @"applications", @"space changed");
                         }];
}

void applications::populate_with_window_ids() {
    std::vector<CGWindowID> wids = space::get_all_window_ids();

    std::unordered_set<pid_t> seen;
    for (CGWindowID wid : wids) {
        pid_t pid;

        CGSConnectionID elementConnection;
        CGSGetWindowOwner(CGSMainConnectionID(), wid, &elementConnection);
        ProcessSerialNumber psn = ProcessSerialNumber();
        CGSGetConnectionPSN(elementConnection, &psn);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        GetProcessPID(&psn, &pid);
#pragma clang diagnostic pop

        if (!seen.count(pid)) {
            add_app(pid);
            seen.insert(pid);
        }
    }

    custom_log(OS_LOG_TYPE_DEFAULT, @"applications", @"apps: %d window_map: %d window_ref_map: %d",
               apps.size(), window_map.size(), window_ref_map.size());
}

void applications::refresh_window_ids() {
    for (application& app : apps) {
        for (const window_element& window : app.windows()) {
            window_map[window.wid] = window;
            window_ref_map[CFHash(window.windowRef)] = window.wid;
        }
    }

    custom_log(OS_LOG_TYPE_DEFAULT, @"applications",
               @"*apps: %d window_map: %d window_ref_map: %d", apps.size(), window_map.size(),
               window_ref_map.size());
}

void applications::add_app(pid_t pid) {
    application app = application(pid);
    if (!app.is_xpc()) {
        apps.push_back(app);
        add_observer(app);

        for (const window_element& window : app.windows()) {
            window_map[window.wid] = window;
            window_ref_map[CFHash(window.windowRef)] = window.wid;
        }
    }
}

void applications::add_window_ref(AXUIElementRef windowRef) {
    CGWindowID wid = CGWindowID();
    _AXUIElementGetWindow(windowRef, &wid);

    window_map[wid] = window_element(windowRef);
    window_ref_map[CFHash(windowRef)] = wid;
}

void applications::remove_window_ref(AXUIElementRef windowRef) {
    window_map.erase(window_ref_map[CFHash(windowRef)]);
    window_ref_map.erase(CFHash(windowRef));
}

void observer_callback(AXObserverRef observer, AXUIElementRef windowRef,
                       CFStringRef notificationName, void* inUserData) {
    applications* apps = (applications*)inUserData;

    if (CFEqual(notificationName, kAXWindowCreatedNotification)) {
        apps->add_window_ref((AXUIElementRef)CFRetain(windowRef));
    } else if (CFEqual(notificationName, kAXUIElementDestroyedNotification)) {
        apps->remove_window_ref(windowRef);
    }
}

void applications::add_observer(application& app) {
    AXObserverRef axObserver;

    // WARNING: starting SCStream triggers kAXWindowCreatedNotification (one per captured window)
    AXObserverCreate(app.pid, &observer_callback, &axObserver);

    AXObserverAddNotification(axObserver, app.axUiElement, kAXWindowCreatedNotification, this);
    AXObserverAddNotification(axObserver, app.axUiElement, kAXUIElementDestroyedNotification,
                              this);
    CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(axObserver),
                       kCFRunLoopDefaultMode);
}
