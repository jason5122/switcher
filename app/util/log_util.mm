#import "util/log_util.h"

void log_with_type(os_log_type_t type, NSString* message, NSString* category) {
    NSString* bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];

    os_log_t customLog = os_log_create([bundleIdentifier UTF8String], [category UTF8String]);

    os_log_with_type(customLog, type, "%{public}@", message);
}
