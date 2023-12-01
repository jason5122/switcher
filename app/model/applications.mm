#import "applications.h"

applications::applications() {
    for (NSRunningApplication* app in NSWorkspace.sharedWorkspace.runningApplications) {}
}
