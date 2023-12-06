#import <Cocoa/Cocoa.h>

@interface CaptureView : NSView

@property(nonatomic) CALayer* contentLayer;

- (instancetype)initWithFrame:(CGRect)frame windowId:(CGWindowID)wid;
- (void)startCapture;
- (void)stopCapture;

@end
