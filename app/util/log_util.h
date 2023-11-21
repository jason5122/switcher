#pragma once

#import <Foundation/Foundation.h>
#import <os/log.h>
#import <string>

void log_with_type(os_log_type_t type, NSString* message, NSString* category);
void log_with_type(os_log_type_t type, std::string str, NSString* category);
