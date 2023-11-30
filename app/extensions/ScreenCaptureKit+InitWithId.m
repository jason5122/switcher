#import "ScreenCaptureKit+InitWithId.h"

@implementation SCWindow (InitWithId)

@dynamic windowID;

- (instancetype _Nonnull)initWithId:(CGWindowID)windowID {
    self = [super init];
    if (self) {
        [self setValue:[NSNumber numberWithInteger:windowID] forKey:@"windowID"];
    }
    return self;
}

@end
