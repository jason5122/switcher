#import <ScreenCaptureKit/ScreenCaptureKit.h>

@interface SCWindow (InitWithId)

@property CGWindowID windowID;

- (instancetype _Nonnull)initWithId:(CGWindowID)windowID;

@end
