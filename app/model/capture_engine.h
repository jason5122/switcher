#import <ScreenCaptureKit/ScreenCaptureKit.h>

@interface ScreenCaptureDelegate : NSObject <SCStreamOutput>
@end

class CaptureEngine {
public:
    CaptureEngine(int width, int height);

private:
    ScreenCaptureDelegate* capture_delegate;
    SCStream* dispatch;

    SCWindow* selected_window;
    NSArray<SCWindow*>* windows;

    SCStreamConfiguration* stream_config;
    SCContentFilter* content_filter;
    NSSet* excluded_window_titles;
    NSSet* excluded_application_names;

    void populate_windows();
    void filter_windows();
};
