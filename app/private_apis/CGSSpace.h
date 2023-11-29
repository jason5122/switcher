#import <Cocoa/Cocoa.h>

typedef size_t CGSSpaceID;
typedef int CGSConnectionID;
extern "C" CGSConnectionID _CGSDefaultConnection();
extern "C" CGSSpaceID CGSSpaceCreate(CGSConnectionID cid, int unknown, CFDictionaryRef options);
extern "C" void CGSSpaceDestroy(CGSConnectionID cid, CGSSpaceID sid);
extern "C" void CGSSpaceSetAbsoluteLevel(const CGSConnectionID cid, CGSSpaceID space, int level);
extern "C" void CGSAddWindowsToSpaces(CGSConnectionID cid, CFArrayRef windows, CFArrayRef spaces);
extern "C" void CGSShowSpaces(CGSConnectionID cid, CFArrayRef spaces);
extern "C" void CGSHideSpaces(CGSConnectionID cid, CFArrayRef spaces);

@interface CGSSpace : NSObject {
    CGSSpaceID identifier;
}

- (instancetype)initWithLevel:(int)level;

- (void)addWindow:(NSWindow*)window;

@end
