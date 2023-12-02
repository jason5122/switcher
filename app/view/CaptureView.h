#import <Cocoa/Cocoa.h>

@interface CaptureView : NSOpenGLView

@property(nonatomic, getter=hasStarted) bool started;

- (id)initWithFrame:(NSRect)frame windowId:(CGWindowID)wid;
- (void)startCapture;
- (void)stopCapture;

@end
