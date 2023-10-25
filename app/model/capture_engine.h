#import <ScreenCaptureKit/ScreenCaptureKit.h>

class CaptureEngine {
public:
    NSArray<SCWindow*>* windows;

    CaptureEngine(int width, int height);

private:
    SCStreamConfiguration* stream_config;
    SCContentFilter* content_filter;
    NSSet* excluded_window_titles;
    NSSet* excluded_application_names;

    void populate_windows();
    void filter_windows();
};
