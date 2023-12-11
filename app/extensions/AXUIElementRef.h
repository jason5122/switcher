#import <Cocoa/Cocoa.h>
#import <vector>

// TODO: measure performance
inline bool AXUIElementIsStandardWindow(AXUIElementRef& windowRef) {
    CFStringRef subroleRef;
    AXUIElementCopyAttributeValue(windowRef, kAXSubroleAttribute, (CFTypeRef*)&subroleRef);
    NSString* subrole = (__bridge NSString*)subroleRef;
    return [subrole isEqual:@"AXStandardWindow"];
}

inline std::vector<AXUIElementRef> AXUIElementGetWindows(AXUIElementRef& applicationRef) {
    std::vector<AXUIElementRef> result;

    CFArrayRef windows;
    AXError err =
        AXUIElementCopyAttributeValue(applicationRef, kAXWindowsAttribute, (CFTypeRef*)&windows);

    if (err == kAXErrorSuccess) {
        for (int i = 0; i < CFArrayGetCount(windows); i++) {
            AXUIElementRef windowRef = (AXUIElementRef)CFArrayGetValueAtIndex(windows, i);
            result.push_back(std::move(windowRef));
        }
    }
    return result;
}
