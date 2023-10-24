#import "LogUtil.h"
#import <Foundation/Foundation.h>
#import <os/log.h>

void log_default(const char* message, const char* category) {
    NSString* bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];

    os_log_t customLog = os_log_create([bundleIdentifier UTF8String], category);

    NSString* defaultMessage = [NSString stringWithCString:message
                                                  encoding:[NSString defaultCStringEncoding]];
    os_log(customLog, "%{public}@", defaultMessage);
}

void log_error(const char* message, const char* category) {
    NSString* bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];

    os_log_t customLog = os_log_create([bundleIdentifier UTF8String], category);

    NSString* errorMessage = [NSString stringWithCString:message
                                                encoding:[NSString defaultCStringEncoding]];
    os_log_error(customLog, "%{public}@", errorMessage);
}
