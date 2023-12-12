#import "extensions/CGWindow.h"
#import "private_apis/AXUI.h"
#import "util/log_util.h"
#import <Cocoa/Cocoa.h>
#import <vector>

inline CFTypeRef AXUIElementGetAttribute(AXUIElementRef& axRef, CFStringRef attribute) {
    CFTypeRef typeRef;
    AXError err = AXUIElementCopyAttributeValue(axRef, attribute, &typeRef);
    if (err != kAXErrorSuccess) {
        custom_log(OS_LOG_TYPE_ERROR, @"axuielement", @"AXError for %@", attribute);
    }
    return typeRef;
}

inline NSString* AXUIElementGetSubrole(AXUIElementRef& windowRef) {
    return (__bridge NSString*)AXUIElementGetAttribute(windowRef, kAXSubroleAttribute);
}

inline bool AXUIElementIsValidWindow(AXUIElementRef& windowRef) {
    NSString* subrole = AXUIElementGetSubrole(windowRef);

    // Ignore Sonoma purple recording icon.
    CGWindowID wid;
    _AXUIElementGetWindow(windowRef, &wid);
    if (wid == 0) return false;  // Sometimes, wid can erroneously be 0.
    if ([subrole isEqual:@"AXDialog"] && [CGWindowGetTitle(wid) isEqual:@"Window"]) return false;

    return [subrole isEqual:@"AXStandardWindow"] || [subrole isEqual:@"AXDialog"];
}

inline std::vector<AXUIElementRef> AXUIElementGetWindows(AXUIElementRef& appRef) {
    std::vector<AXUIElementRef> result;
    CFArrayRef windows = (CFArrayRef)AXUIElementGetAttribute(appRef, kAXWindowsAttribute);
    for (int i = 0; i < CFArrayGetCount(windows); i++) {
        AXUIElementRef windowRef = (AXUIElementRef)CFArrayGetValueAtIndex(windows, i);
        result.push_back(std::move(windowRef));
    }
    return result;
}
