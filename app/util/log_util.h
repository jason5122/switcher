#pragma once

#import <Foundation/Foundation.h>
#import <os/log.h>

void log_with_type(os_log_type_t type, NSString* message, NSString* category);
