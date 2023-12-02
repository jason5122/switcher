#import <Cocoa/Cocoa.h>

@interface CaptureView : NSOpenGLView

- (id)initWithFrame:(NSRect)frame windowId:(CGWindowID)wid;
- (void)startCapture;
- (void)stopCapture;

@end
