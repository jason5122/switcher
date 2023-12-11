#import <Cocoa/Cocoa.h>

// TODO: measure performance
inline bool AXUIElementIsStandardWindow(AXUIElementRef& windowRef) {
    CFStringRef subroleRef;
    AXUIElementCopyAttributeValue(windowRef, kAXSubroleAttribute, (CFTypeRef*)&subroleRef);
    NSString* subrole = (__bridge NSString*)subroleRef;
    return [subrole isEqual:@"AXStandardWindow"];
}
