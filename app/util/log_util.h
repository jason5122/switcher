#pragma once

#import <Foundation/Foundation.h>
#import <os/log.h>

void custom_log(os_log_type_t type, NSString* category, NSString* format, ...);

// https://stackoverflow.com/a/12994075/14698275
#ifdef __cplusplus
extern "C" {
#endif

int hi();

#ifdef __cplusplus
}
#endif
