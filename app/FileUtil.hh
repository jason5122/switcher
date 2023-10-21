#ifndef FILEUTIL_H
#define FILEUTIL_H

#import <Foundation/Foundation.h>
#import <string>
#import <sys/stat.h>

const char* resource_path(const std::string& name);
char* read_file(const std::string& name);

#endif
