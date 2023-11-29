#import <Cocoa/Cocoa.h>

extern "C" CFArrayRef CGSCopyWindowsWithOptionsAndTags(CGSConnectionID cid, int owner,
                                                       CFArrayRef spaces, int options,
                                                       int* setTags, int* clearTags);
extern "C" CFArrayRef CGSCopyManagedDisplaySpaces(CGSConnectionID cid);
