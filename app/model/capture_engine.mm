#import "model/capture_engine.h"
#import "util/log_util.h"

CaptureEngine::CaptureEngine(int width, int height) {
    stream_config = [[SCStreamConfiguration alloc] init];

    [stream_config setWidth:width];
    [stream_config setHeight:height];

    [stream_config setQueueDepth:8];
    [stream_config setShowsCursor:NO];
    [stream_config setColorSpaceName:kCGColorSpaceSRGB];
    [stream_config setPixelFormat:'BGRA'];

    excluded_window_titles = [NSSet setWithObjects:@"Menubar", @"Item-0", nil];
    excluded_application_names = [NSSet setWithObjects:@"Control Center", @"Dock", nil];

    populate_windows();
    filter_windows();

    // this->content_filter =
    //     [[SCContentFilter alloc] initWithDesktopIndependentWindow:target_window];
}

void CaptureEngine::populate_windows() {
    // https://stackoverflow.com/a/14697903/14698275
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    typedef void (^shareable_content_callback)(SCShareableContent*, NSError*);
    shareable_content_callback new_content_received =
        ^void(SCShareableContent* shareable_content, NSError* error) {
          if (error == nil) {
              windows = shareable_content.windows;
          } else {
              log_error("error building content list", "CaptureEngine.mm");
          }

          dispatch_semaphore_signal(sem);
        };

    [SCShareableContent getShareableContentExcludingDesktopWindows:TRUE
                                               onScreenWindowsOnly:TRUE
                                                 completionHandler:new_content_received];

    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
}

void CaptureEngine::filter_windows() {
    NSArray* filteredWindows = [windows
        filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(SCWindow* window,
                                                                          NSDictionary* bindings) {
          return ![excluded_window_titles containsObject:window.title] &&
                 ![excluded_application_names
                     containsObject:window.owningApplication.applicationName];
        }]];

    windows = filteredWindows;

    const char* message = [[NSString stringWithFormat:@"%lu", [windows count]] UTF8String];
    log_default(message, "capture_engine.mm");
    for (SCWindow* window in windows) {
        message =
            [[NSString stringWithFormat:@"%@ %@", window.title,
                                        window.owningApplication.applicationName] UTF8String];
        log_default(message, "capture_engine.mm");
    }
}
