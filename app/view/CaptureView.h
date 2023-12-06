#import <Cocoa/Cocoa.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>

@interface CaptureView : NSView

@property(nonatomic) CALayer* contentLayer;

- (instancetype)initWithFrame:(CGRect)frame configuration:(SCStreamConfiguration*)config;
- (void)updateWithFilter:(SCContentFilter*)filter;
- (void)startCapture;
- (void)stopCapture;

@end
