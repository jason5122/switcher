#import "view/CaptureView.h"
#import <Cocoa/Cocoa.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>

@interface ScreenCaptureDelegate : NSObject <SCStreamOutput> {
    CaptureView* captureView;
}

- (instancetype)initWithCaptureView:(CaptureView*)captureView;

@end

class capture_engine {
public:
    capture_engine(CaptureView* captureView);
    void tick();
    void render();

private:
    CaptureView* captureView;
    ScreenCaptureDelegate* captureDelegate;

    void init_quad(IOSurfaceRef surface);
};
