#import <ScreenCaptureKit/ScreenCaptureKit.h>

class capture_content {
public:
    NSArray<SCWindow*>* windows;

    capture_content();
    void get_content();
    void build_window_list();

private:
    SCShareableContent* shareable_content;
    dispatch_semaphore_t shareable_content_available;
};
