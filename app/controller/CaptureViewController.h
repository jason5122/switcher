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

@property(nonatomic) CapturePreview* captureView;
@property(nonatomic) CGWindowID wid;

- (instancetype)initWithWindowId:(CGWindowID)wid
                            size:(CGSize)theSize
                    innerPadding:(CGFloat)innerPadding
                titleTextPadding:(CGFloat)titleTextPadding;
- (void)updateWithWindowId:(CGWindowID)wid;
- (void)highlight;
- (void)unhighlight;

@end
