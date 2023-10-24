#import <ScreenCaptureKit/ScreenCaptureKit.h>

class CaptureEngine {
    SCStreamConfiguration* stream_config;
    SCContentFilter* content_filter;

public:
    SCShareableContent* shareable_content;

    CaptureEngine(int width, int height);

    void screen_capture_build_content_list();
};
