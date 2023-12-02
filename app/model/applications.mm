#import "applications.h"
#import "util/log_util.h"

applications::applications() {
    for (NSRunningApplication* runningApp in NSWorkspace.sharedWorkspace.runningApplications) {
        application app = application(runningApp);

        if (!app.is_xpc() &&
            runningApp.activationPolicy != NSApplicationActivationPolicyProhibited) {
            app.populate_initial_windows();
            add_observer(app);

            for (const window_element& window : app.windows) {
                // custom_log(OS_LOG_TYPE_DEFAULT, @"applications", @"%@", app.name());
                window_map[window.wid] = window;
                // window_ref_map[window.windowRef] = window;
                // window_refs.push_back(window.windowRef);
                window_refs.insert(CFHash(window.windowRef));

                custom_log(OS_LOG_TYPE_DEFAULT, @"applications", @"%d", window.windowRef);
            }
        }
    }

    // custom_log(OS_LOG_TYPE_DEFAULT, @"applications", @"%d", window_map.size());
}

void observer_callback(AXObserverRef observer, AXUIElementRef windowRef,
                       CFStringRef notificationName, void* inUserData) {
    applications* apps = (applications*)inUserData;

    if (CFEqual(notificationName, kAXWindowCreatedNotification)) {
        CGWindowID wid = CGWindowID();
        _AXUIElementGetWindow(windowRef, &wid);
        custom_log(OS_LOG_TYPE_DEFAULT, @"applications", @"window created wid: %d", wid);

        // window_element window = window_element(windowRef);
        // custom_log(OS_LOG_TYPE_DEFAULT, @"applications", @"%d", window.wid);
        // custom_log(OS_LOG_TYPE_DEFAULT, @"applications", @"%d",
        // apps->window_map.size());

        // apps->window_map[wid] = window;
        apps->window_refs.insert(CFHash(windowRef));
    } else if (CFEqual(notificationName, kAXUIElementDestroyedNotification)) {
        apps->window_refs.erase(CFHash(windowRef));
    }
}

void applications::add_observer(application& app) {
    AXObserverRef axObserver;

    // WARNING: starting SCStream triggers kAXWindowCreatedNotification (one per captured window)
    AXObserverCreate(app.runningApp.processIdentifier, &observer_callback, &axObserver);

    AXObserverAddNotification(axObserver, app.axUiElement, kAXWindowCreatedNotification, this);
    AXObserverAddNotification(axObserver, app.axUiElement, kAXUIElementDestroyedNotification,
                              this);
    CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(axObserver),
                       kCFRunLoopDefaultMode);
}
