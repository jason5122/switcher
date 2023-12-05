#import "capture_preview_swift.h"
#import "model/window_element.h"
#import "view/CACaptureView.h"
#import "view/CaptureView.h"
#import <Cocoa/Cocoa.h>

@interface CaptureViewController : NSViewController {
    CGSize size;
    NSTextField* titleText;
    NSImageView* iconView;
}

// @property(nonatomic) CaptureView* captureView;
// @property(nonatomic) CACaptureView* captureView;
@property(nonatomic) CapturePreview* captureView;
@property(nonatomic) CGWindowID wid;

- (instancetype)initWithWindowId:(CGWindowID)wid
                            size:(CGSize)size
                    innerPadding:(CGFloat)innerPadding
                titleTextPadding:(CGFloat)theTitleTextPadding;
- (void)updateWithWindowId:(CGWindowID)wid;
- (void)highlight;
- (void)unhighlight;

@end
