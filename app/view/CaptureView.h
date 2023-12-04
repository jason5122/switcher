#import <Cocoa/Cocoa.h>

@interface CaptureView : NSOpenGLView

- (instancetype)initWithFrame:(NSRect)frame windowId:(CGWindowID)wid;
- (void)startCapture;
- (void)stopCapture;

@end
