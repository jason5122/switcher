#import "applications.h"
#import "private_apis/SkyLight.h"
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

                aaa.push_back(window.windowRef);
            }
        }
    }

    // custom_log(OS_LOG_TYPE_DEFAULT, @"applications", @"%d", window_map.size());
}

void applications::SHIT(AXUIElementRef inRef) {
    std::vector<AXUIElementRef> refs;
    // ProcessSerialNumber finalPsn;

    for (NSRunningApplication* runningApp in NSWorkspace.sharedWorkspace.runningApplications) {
        if (![runningApp.localizedName isEqual:@"Sublime Text"]) continue;

        AXUIElementRef axUiElement = AXUIElementCreateApplication(runningApp.processIdentifier);

        AXUIElementCreateApplication(runningApp.processIdentifier);
        CFArrayRef windowList;
        AXUIElementCopyAttributeValue(axUiElement, kAXWindowsAttribute, (CFTypeRef*)&windowList);

        for (int i = 0; i < CFArrayGetCount(windowList); i++) {
            AXUIElementRef windowRef = (AXUIElementRef)CFArrayGetValueAtIndex(windowList, i);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            ProcessSerialNumber psn;
            GetProcessForPID(runningApp.processIdentifier, &psn);
#pragma clang diagnostic pop

            CFBooleanRef minimizedRef;
            AXUIElementCopyAttributeValue(windowRef, kAXMinimizedAttribute,
                                          (CFTypeRef*)&minimizedRef);
            bool is_minimized = CFBooleanGetValue(minimizedRef);
            if (!is_minimized) {
                refs.push_back(windowRef);
            }
        }
    }

    // std::string s = "[";
    // for (AXUIElementRef ref : refs) {
    //     s += std::to_string(CFHash(ref)) + ", ";
    // }
    // s += ']';
    // custom_log(OS_LOG_TYPE_DEFAULT, @"applications", @"%s", s.c_str());

    custom_log(OS_LOG_TYPE_DEFAULT, @"applications", @"before %lu", CFHash(refs.back()));
    set_ay(refs.back());

    // _SLPSSetFrontProcessWithOptions(&finalPsn, 0, kSLPSNoWindows);
    // AXUIElementPerformAction(refs.back(), kAXRaiseAction);

    // custom_log(OS_LOG_TYPE_DEFAULT, @"applications", @"%d", window_map.size());
}

void applications::set_ay(AXUIElementRef newAy) {
    ay = newAy;
}

void applications::goddamnit(AXUIElementRef windowRef) {
    custom_log(OS_LOG_TYPE_DEFAULT, @"applications", @"ugh %lu", CFHash(windowRef));
    ay = windowRef;
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

        // apps->aaa.push_back(windowRef);
        // apps->ay = windowRef;
        // apps->SHIT(nullptr);
        // apps->set_ay(windowRef);
        apps->goddamnit(windowRef);

        apps->window_map[wid] = window_element(windowRef);
        apps->ref_map[wid] = windowRef;
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
