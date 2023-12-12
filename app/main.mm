#import "AppDelegate.h"
#import "controller/shortcut_controller.h"
#import "util/log_util.h"
#import <Cocoa/Cocoa.h>

void HandleException(NSException* exception) {
    custom_log(OS_LOG_TYPE_ERROR, @"main", @"%@ %@", exception.name, exception.reason);
    shortcut_controller::set_native_command_tab_enabled(true);
    exit(0);
}

void SignalHandler(int sig) {
    custom_log(OS_LOG_TYPE_ERROR, @"main", @"caught signal: %s", sys_signame[sig]);
    shortcut_controller::set_native_command_tab_enabled(true);
    exit(0);
}

// https://www.cocoawithlove.com/2010/05/handling-unhandled-exceptions-and.html
void InstallUncaughtExceptionHandler() {
    NSSetUncaughtExceptionHandler(&HandleException);
    signal(SIGABRT, &SignalHandler);
    signal(SIGILL, &SignalHandler);
    signal(SIGSEGV, &SignalHandler);
    signal(SIGFPE, &SignalHandler);
    signal(SIGBUS, &SignalHandler);
    signal(SIGPIPE, &SignalHandler);
    signal(SIGTERM, &SignalHandler);
}

int main() {
    InstallUncaughtExceptionHandler();

    @autoreleasepool {
        NSApplication* app = NSApplication.sharedApplication;
        AppDelegate* appDelegate = [[AppDelegate alloc] init];

        app.activationPolicy = NSApplicationActivationPolicyAccessory;
        app.delegate = appDelegate;

        [app run];
    }
}
