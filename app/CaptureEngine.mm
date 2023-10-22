#include "CaptureEngine.hh"
#import <os/log.h>

CaptureEngine::CaptureEngine(int width, int height) {
    this->stream_properties = [[SCStreamConfiguration alloc] init];

    [this->stream_properties setWidth:width];
    [this->stream_properties setHeight:height];

    [this->stream_properties setQueueDepth:8];
    [this->stream_properties setShowsCursor:NO];
    [this->stream_properties setColorSpaceName:kCGColorSpaceSRGB];
    [this->stream_properties setPixelFormat:'BGRA'];

    // this->content_filter =
    //     [[SCContentFilter alloc] initWithDesktopIndependentWindow:target_window];
}

void CaptureEngine::screen_capture_build_content_list() {
    os_log_t customLog = os_log_create("com.jason.switcher", "CaptureEngine.mm");

    typedef void (^shareable_content_callback)(SCShareableContent*, NSError*);
    shareable_content_callback new_content_received =
        ^void(SCShareableContent* shareable_content, NSError* error) {
          if (error == nil) {
              this->shareable_content = shareable_content;
              os_log_with_type(customLog, OS_LOG_TYPE_ERROR, "success building content list");
          } else {
              os_log_with_type(customLog, OS_LOG_TYPE_ERROR, "error building content list");
          }
        };

    [SCShareableContent getShareableContentExcludingDesktopWindows:TRUE
                                               onScreenWindowsOnly:TRUE
                                                 completionHandler:new_content_received];
}
