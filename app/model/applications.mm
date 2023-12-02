#import "applications.h"
#import "util/log_util.h"

applications::applications() {
    for (NSRunningApplication* runningApp in NSWorkspace.sharedWorkspace.runningApplications) {
        application app = application(runningApp);

        if (![app.name() isEqual:@"Sublime Text"]) continue;

        if (!app.is_xpc() &&
            runningApp.activationPolicy != NSApplicationActivationPolicyProhibited) {
            app.populate_initial_windows();
            add_observer(app);

            for (const window_element& window : app.windows) {
                // custom_log(OS_LOG_TYPE_DEFAULT, @"applications", @"%@", app.name());
                window_map[window.wid] = window;
                window_ref_map[CFHash(window.windowRef)] = window.wid;
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

        CFStringRef titleRef;
        CFStringRef roleRef;
        CFStringRef subroleRef;
        AXUIElementCopyAttributeValue(windowRef, kAXTitleAttribute, (CFTypeRef*)&titleRef);
        AXUIElementCopyAttributeValue(windowRef, kAXRoleAttribute, (CFTypeRef*)&roleRef);
        AXUIElementCopyAttributeValue(windowRef, kAXSubroleAttribute, (CFTypeRef*)&subroleRef);
        NSString* title = (__bridge NSString*)titleRef;
        NSString* role = (__bridge NSString*)roleRef;
        NSString* subrole = (__bridge NSString*)subroleRef;
        if (![subrole isEqual:@"AXStandardWindow"]) return;
        custom_log(OS_LOG_TYPE_DEFAULT, @"applications", @"%@ %@ %@ %lu", title, role, subrole,
                   CFHash(windowRef));

        apps->window_map[wid] = window_element(windowRef);
        apps->window_ref_map[CFHash(windowRef)] = wid;
    } else if (CFEqual(notificationName, kAXUIElementDestroyedNotification)) {
        apps->window_map.erase(apps->window_ref_map[CFHash(windowRef)]);
        apps->window_ref_map.erase(CFHash(windowRef));
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
