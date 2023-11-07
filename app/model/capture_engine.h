#import "gl_cocoa.h"
#import <Cocoa/Cocoa.h>

struct screen_capture;

class CaptureEngine {
public:
    CaptureEngine(NSOpenGLContext* context);
    void screen_capture_video_tick();
    void screen_capture_video_render();

private:
    screen_capture* sc;
};
