#import "capture_preview_swift.h"
#import "model/window_element.h"
#import "view/CACaptureView.h"
#import "view/CaptureView.h"
#import <Cocoa/Cocoa.h>

@interface CaptureViewController : NSViewController

@property(nonatomic) CaptureView* captureView;
@property(nonatomic) CACaptureView* caCaptureView;
@property(nonatomic) CapturePreview* capturePreview;
@property(nonatomic) CGWindowID wid;

- (instancetype)initWithWindowId:(CGWindowID)wid
                            size:(CGSize)size
                    innerPadding:(CGFloat)innerPadding
                titleTextPadding:(CGFloat)theTitleTextPadding;
- (void)highlight;
- (void)unhighlight;

@end
