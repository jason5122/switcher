#import <Cocoa/Cocoa.h>

typedef size_t CGSSpaceID;
typedef int CGSConnectionID;
extern CGSConnectionID _CGSDefaultConnection();
extern CGSSpaceID CGSSpaceCreate(CGSConnectionID cid, int unknown, CFDictionaryRef options);
extern void CGSSpaceDestroy(CGSConnectionID cid, CGSSpaceID sid);
extern void CGSSpaceSetAbsoluteLevel(const CGSConnectionID cid, CGSSpaceID space, int level);
extern void CGSAddWindowsToSpaces(CGSConnectionID cid, CFArrayRef windows, CFArrayRef spaces);
extern void CGSShowSpaces(CGSConnectionID cid, CFArrayRef spaces);
extern void CGSHideSpaces(CGSConnectionID cid, CFArrayRef spaces);

@interface CGSSpace : NSObject {
    CGSSpaceID identifier;
}

- (instancetype)initWithLevel:(int)level;

- (void)addWindow:(NSWindow*)window;

@end
