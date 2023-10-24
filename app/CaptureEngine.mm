#import "CaptureEngine.hh"
#import <os/log.h>

CaptureEngine::CaptureEngine(int width, int height) {
  this->stream_config = [[SCStreamConfiguration alloc] init];

  [this->stream_config setWidth:width];
  [this->stream_config setHeight:height];

  [this->stream_config setQueueDepth:8];
  [this->stream_config setShowsCursor:NO];
  [this->stream_config setColorSpaceName:kCGColorSpaceSRGB];
  [this->stream_config setPixelFormat:'BGRA'];

  // this->content_filter =
  //     [[SCContentFilter alloc] initWithDesktopIndependentWindow:target_window];
}

void CaptureEngine::screen_capture_build_content_list() {
  os_log_t customLog = os_log_create("com.jason.switcher", "CaptureEngine.mm");

  // https://stackoverflow.com/a/14697903/14698275
  dispatch_semaphore_t sem = dispatch_semaphore_create(0);

  typedef void (^shareable_content_callback)(SCShareableContent*, NSError*);
  shareable_content_callback new_content_received =
      ^void(SCShareableContent* shareable_content, NSError* error) {
        if (error == nil) {
          this->shareable_content = shareable_content;
        } else {
          os_log_error(customLog, "error building content list");
        }

        dispatch_semaphore_signal(sem);
      };

  [SCShareableContent getShareableContentExcludingDesktopWindows:TRUE
                                             onScreenWindowsOnly:TRUE
                                               completionHandler:new_content_received];

  dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
}
