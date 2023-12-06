#import <Cocoa/Cocoa.h>

@interface GLCaptureView : NSOpenGLView

- (instancetype)initWithFrame:(NSRect)frame windowId:(CGWindowID)wid;
- (void)startCapture;
- (void)stopCapture;

@end
