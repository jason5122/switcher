#import "NSImage+InitWithId.h"
#import "private_apis/CGS.h"

@implementation NSImage (InitWithId)

- (instancetype)initWithId:(CGWindowID)windowID {
    CGSConnectionID elementConnection;
    CGSGetWindowOwner(CGSMainConnectionID(), windowID, &elementConnection);
    ProcessSerialNumber psn = ProcessSerialNumber();
    CGSGetConnectionPSN(elementConnection, &psn);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    FSRef fsRef;
    GetProcessBundleLocation(&psn, &fsRef);
    IconRef iconRef;
    GetIconRefFromFileInfo(&fsRef, 0, NULL, 0, NULL, kIconServicesNormalUsageFlag, &iconRef, NULL);
    return [self initWithIconRef:iconRef];
#pragma clang diagnostic pop
}

@end
