#import "util/log_util.h"
#import <os/log.h>

void log_default(NSString* message, NSString* category) {
    NSString* bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];

    os_log_t customLog = os_log_create([bundleIdentifier UTF8String], [category UTF8String]);

    os_log(customLog, "%{public}@", message);
}

void log_error(NSString* message, NSString* category) {
    NSString* bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];

    os_log_t customLog = os_log_create([bundleIdentifier UTF8String], [category UTF8String]);

    os_log_error(customLog, "%{public}@", message);
}
