#import "view/CaptureView.h"
#import <Cocoa/Cocoa.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>

struct screen_capture;

@interface ScreenCaptureDelegate : NSObject <SCStreamOutput> {
    CaptureView* captureView;
    screen_capture* sc;
}

- (instancetype)init:(CaptureView*)captureView screenCapture:(screen_capture*)sc;

@end

class capture_engine {
public:
    capture_engine(CaptureView* captureView);
    bool start_capture();
    bool stop_capture();
    void tick();
    void render();

private:
    CaptureView* captureView;
    ScreenCaptureDelegate* captureDelegate;

    screen_capture* sc;

    void init_quad(IOSurfaceRef surface);
};
