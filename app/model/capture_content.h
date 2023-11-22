#import <ScreenCaptureKit/ScreenCaptureKit.h>

class capture_content {
public:
    capture_content();
    void build_content_list();
    NSArray* get_filtered_windows();

private:
    SCShareableContent* shareable_content;
    dispatch_semaphore_t shareable_content_available;
};
