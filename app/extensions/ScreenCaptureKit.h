#import <ScreenCaptureKit/ScreenCaptureKit.h>

@interface SCWindow (Custom)

@property CGWindowID windowID;

- (instancetype _Nonnull)initWithId:(CGWindowID)windowID;

@end
