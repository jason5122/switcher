#import "applications.h"
#import "model/application.h"
#import "util/log_util.h"

applications::applications() {
    for (NSRunningApplication* runningApp in NSWorkspace.sharedWorkspace.runningApplications) {
        application app = application(runningApp);

        if (!app.is_xpc() &&
            runningApp.activationPolicy != NSApplicationActivationPolicyProhibited) {
            app.populate_initial_windows();

            for (const window_element& window : app.windows) {
                // custom_log(OS_LOG_TYPE_DEFAULT, @"applications", @"%@", app.name());
                window_map[window.wid] = window;
            }
        }
    }

    // custom_log(OS_LOG_TYPE_DEFAULT, @"applications", @"%d", window_map.size());
}
