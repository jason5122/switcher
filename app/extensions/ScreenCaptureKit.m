#import "ScreenCaptureKit.h"

@implementation SCWindow (Custom)

@dynamic windowID;

- (instancetype _Nonnull)initWithId:(CGWindowID)windowID {
    self = [super init];
    if (self) {
        [self setValue:[NSNumber numberWithInteger:windowID] forKey:@"windowID"];
    }
    return self;
}

@end
