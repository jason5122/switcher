#import "model/capture_engine.h"
#import "util/log_util.h"
#import <os/log.h>

@interface ScreenCaptureDelegate : NSObject <SCStreamOutput>

@property struct screen_capture* sc;

@end

struct screen_capture {
    // obs_source_t* source;

    // gs_samplerstate_t* sampler;
    // gs_effect_t* effect;
    // gs_texture_t* tex;
    // gs_vertbuffer_t* vertbuf;

    // NSRect frame;
    // bool hide_cursor;
    // bool show_hidden_windows;
    // bool show_empty_names;

    // SCStream* disp;
    // SCStreamConfiguration* stream_properties;
    // SCShareableContent* shareable_content;
    // ScreenCaptureDelegate* capture_delegate;

    // os_event_t* disp_finished;
    // os_event_t* stream_start_completed;
    // os_sem_t* shareable_content_available;
    // IOSurfaceRef current, prev;

    // pthread_mutex_t mutex;

    // unsigned capture_type;
    // CGDirectDisplayID display;
    // CGWindowID window;
    // NSString* application_id;
};

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

    selected_window = [windows firstObject];

    content_filter = [[SCContentFilter alloc] initWithDesktopIndependentWindow:selected_window];

    for (SCWindow* window in windows) {
        log_default(window.title, @"capture_engine.mm");
    }

    SCStream* disp = [[SCStream alloc] initWithFilter:content_filter
                                        configuration:stream_config
                                             delegate:nil];

    ScreenCaptureDelegate* capture_delegate;

    NSError* error = nil;
    BOOL did_add_output = [disp addStreamOutput:capture_delegate
                                           type:SCStreamOutputTypeScreen
                             sampleHandlerQueue:nil
                                          error:&error];
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
              log_error(@"error building content list", @"CaptureEngine.mm");
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

    log_default([NSString stringWithFormat:@"%lu", [windows count]], @"capture_engine.mm");
}

@implementation ScreenCaptureDelegate

- (void)stream:(SCStream*)stream
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
                   ofType:(SCStreamOutputType)type {
    if (self.sc != NULL) {
        if (type == SCStreamOutputTypeScreen) {
            // screen_stream_video_update(self.sc, sampleBuffer);
        }
    }
}

@end
