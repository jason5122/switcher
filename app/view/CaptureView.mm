#import "CaptureView.h"
#import "extensions/ScreenCaptureKit+InitWithId.h"
#import "util/log_util.h"
#import <pthread.h>

@interface CaptureOutput : NSObject <SCStreamOutput> {
    // https://mobiarch.wordpress.com/2014/02/05/circular-reference-and-arc/
    __weak CaptureView* captureView;
    dispatch_queue_t serialQueue;
}

- (instancetype)initWithView:(CaptureView*)captureView;

@end

@interface CaptureView () {
    CaptureOutput* captureDelegate;
    SCStream* disp;
    dispatch_semaphore_t startedSem;

@public
    pthread_mutex_t mutex;
}
@end

@implementation CaptureView

- (instancetype)initWithFrame:(CGRect)frame windowId:(CGWindowID)wid {
    self = [super initWithFrame:frame];
    if (self) {
        self.wantsLayer = true;

        // self.layer.backgroundColor = NSColor.redColor.CGColor;

        startedSem = dispatch_semaphore_create(0);
        pthread_mutex_init(&mutex, NULL);

        SCStreamConfiguration* streamConfig = [[SCStreamConfiguration alloc] init];
        streamConfig.width = frame.size.width * 2;
        streamConfig.height = frame.size.height * 2;
        streamConfig.queueDepth = 8;
        streamConfig.showsCursor = false;
        streamConfig.colorSpaceName = kCGColorSpaceSRGB;

        SCWindow* targetWindow = [[SCWindow alloc] initWithId:wid];
        SCContentFilter* contentFilter =
            [[SCContentFilter alloc] initWithDesktopIndependentWindow:targetWindow];
        disp = [[SCStream alloc] initWithFilter:contentFilter
                                  configuration:streamConfig
                                       delegate:nil];

        captureDelegate = [[CaptureOutput alloc] initWithView:self];

        NSError* error = nil;
        BOOL did_add_output = [disp addStreamOutput:captureDelegate
                                               type:SCStreamOutputTypeScreen
                                 sampleHandlerQueue:nil
                                              error:&error];
        if (!did_add_output) {
            custom_log(OS_LOG_TYPE_ERROR, @"ca-capture-view", error.localizedFailureReason);
        }
    }
    return self;
}

- (void)startCapture {
    dispatch_semaphore_t stream_start_completed = dispatch_semaphore_create(0);

    __block BOOL success = false;
    [disp startCaptureWithCompletionHandler:^(NSError* _Nullable error) {
      success = (BOOL)(error == nil);
      if (!success) {
          custom_log(OS_LOG_TYPE_ERROR, @"ca-capture-view", error.localizedFailureReason);
      }
      dispatch_semaphore_signal(stream_start_completed);
    }];
    dispatch_semaphore_wait(stream_start_completed, DISPATCH_TIME_FOREVER);

    if (!success) {
        custom_log(OS_LOG_TYPE_ERROR, @"ca-capture-view", @"start capture failed");
    } else {
        dispatch_semaphore_signal(startedSem);
    }
}

- (void)stopCapture {
    dispatch_semaphore_wait(startedSem, DISPATCH_TIME_FOREVER);

    dispatch_semaphore_t stream_stop_completed = dispatch_semaphore_create(0);

    __block BOOL success = false;
    [disp stopCaptureWithCompletionHandler:^(NSError* _Nullable error) {
      success = (BOOL)(error == nil);
      if (!success) {
          custom_log(OS_LOG_TYPE_ERROR, @"ca-capture-view", error.localizedFailureReason);
      }
      dispatch_semaphore_signal(stream_stop_completed);
    }];
    dispatch_semaphore_wait(stream_stop_completed, DISPATCH_TIME_FOREVER);

    if (!success) {
        custom_log(OS_LOG_TYPE_ERROR, @"ca-capture-view", @"stop capture failed");
    }
}

@end

@implementation CaptureOutput

- (instancetype)initWithView:(CaptureView*)theCaptureView {
    self = [super init];
    if (self) {
        captureView = theCaptureView;
        serialQueue = dispatch_queue_create("com.jason.switcher", NULL);
    }
    return self;
}

- (void)stream:(SCStream*)stream
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
                   ofType:(SCStreamOutputType)type {
    if (type == SCStreamOutputTypeScreen) {
        IOSurfaceRef surface = [self getFrame:sampleBuffer];
        dispatch_sync(serialQueue, ^{
          if (surface) {
              captureView.layer.contents = (__bridge id)surface;
          }
        });
    }
}

- (IOSurfaceRef)getFrame:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    IOSurfaceRef surface = CVPixelBufferGetIOSurface(imageBuffer);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);

    return surface;
}

@end
