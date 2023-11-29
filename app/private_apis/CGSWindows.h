#import <Cocoa/Cocoa.h>

typedef uint64_t CGSManagedDisplay;

extern "C" CGSManagedDisplay kCGSPackagesMainDisplayIdentifier;

extern "C" CFArrayRef CGSCopyWindowsWithOptionsAndTags(CGSConnectionID cid, int owner,
                                                       CFArrayRef spaces, int options,
                                                       int* setTags, int* clearTags);
extern "C" CFArrayRef CGSCopyManagedDisplaySpaces(CGSConnectionID cid);
extern "C" CGSSpaceID CGSManagedDisplayGetCurrentSpace(CGSConnectionID cid,
                                                       CGSManagedDisplay display);
extern "C" CGWindowLevel CGSGetWindowLevel(CGSConnectionID cid, CGWindowID wid,
                                           CGWindowLevel* level);
