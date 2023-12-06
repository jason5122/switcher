#import <Cocoa/Cocoa.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>

@interface GLCaptureView : NSOpenGLView

@property(nonatomic, getter=isPrepared) bool prepared;

- (instancetype)initWithFrame:(CGRect)frame configuration:(SCStreamConfiguration*)config;
- (void)updateWithFilter:(SCContentFilter*)filter;
- (void)startCapture;
- (void)stopCapture;

@end
