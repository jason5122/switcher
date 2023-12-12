#import "CaptureView.h"
#import "util/log_util.h"

@interface CaptureOutput : NSObject <SCStreamOutput> {
    // https://mobiarch.wordpress.com/2014/02/05/circular-reference-and-arc/
    __weak CaptureView* captureView;
    dispatch_queue_t serialQueue;
}

- (instancetype)initWithView:(CaptureView*)captureView;

@end

@interface CaptureView () {
    CaptureOutput* captureOutput;
    SCStream* stream;
    dispatch_semaphore_t startedSem;
    SCContentFilter* filter;
    SCStreamConfiguration* config;
}
@end

@implementation CaptureView

- (instancetype)initWithFrame:(CGRect)frame configuration:(SCStreamConfiguration*)theConfig {
    self = [super initWithFrame:frame];
    if (self) {
        startedSem = dispatch_semaphore_create(0);
        config = theConfig;

        self.wantsLayer = true;
    }
    return self;
}

- (void)updateWithFilter:(SCContentFilter*)theFilter {
    filter = theFilter;
}

- (void)startCapture {
    stream = [[SCStream alloc] initWithFilter:filter configuration:config delegate:nil];
    captureOutput = [[CaptureOutput alloc] initWithView:self];
    NSError* error = nil;
    BOOL did_add_output = [stream addStreamOutput:captureOutput
                                             type:SCStreamOutputTypeScreen
                               sampleHandlerQueue:nil
                                            error:&error];
    if (!did_add_output) {
        custom_log(OS_LOG_TYPE_ERROR, @"capture-view", error.localizedFailureReason);
    }

    dispatch_semaphore_t stream_start_completed = dispatch_semaphore_create(0);

    __block BOOL success = false;
    [stream startCaptureWithCompletionHandler:^(NSError* _Nullable error) {
      success = (BOOL)(error == nil);
      if (!success) {
          custom_log(OS_LOG_TYPE_ERROR, @"capture-view", error.localizedFailureReason);
      }
      dispatch_semaphore_signal(stream_start_completed);
    }];
    dispatch_semaphore_wait(stream_start_completed, DISPATCH_TIME_FOREVER);

    if (!success) {
        custom_log(OS_LOG_TYPE_ERROR, @"capture-view", @"start capture failed");
    }
    dispatch_semaphore_signal(startedSem);
}

- (void)stopCapture {
    dispatch_semaphore_wait(startedSem, DISPATCH_TIME_FOREVER);

    dispatch_semaphore_t stream_stop_completed = dispatch_semaphore_create(0);

    __block BOOL success = false;
    [stream stopCaptureWithCompletionHandler:^(NSError* _Nullable error) {
      success = (BOOL)(error == nil);
      if (!success) {
          custom_log(OS_LOG_TYPE_ERROR, @"capture-view", error.localizedFailureReason);
      }
      dispatch_semaphore_signal(stream_stop_completed);
    }];
    dispatch_semaphore_wait(stream_stop_completed, DISPATCH_TIME_FOREVER);

    if (!success) {
        custom_log(OS_LOG_TYPE_ERROR, @"capture-view", @"stop capture failed");
    }
}

@end

@implementation CaptureOutput

- (instancetype)initWithView:(CaptureView*)theCaptureView {
    self = [super init];
    if (self) {
        captureView = theCaptureView;
        serialQueue = dispatch_queue_create("com.jason5122.switcher", NULL);
    }
    return self;
}

- (void)stream:(SCStream*)stream
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
                   ofType:(SCStreamOutputType)type {
    if (type == SCStreamOutputTypeScreen) {
        IOSurfaceRef frame = [self createFrame:sampleBuffer];
        if (!frame) {
            // custom_log(OS_LOG_TYPE_ERROR, @"capture-view", @"invalid frame");
            return;
        }
        // custom_log(OS_LOG_TYPE_DEFAULT, @"capture-view", @"good");
        dispatch_sync(serialQueue, ^{ captureView.layer.contents = (__bridge id)frame; });
    }
}

- (IOSurfaceRef)createFrame:(CMSampleBufferRef)sampleBuffer {
    // Retrieve the array of metadata attachments from the sample buffer.
    CFArrayRef attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, false);
    if (attachmentsArray == nil || CFArrayGetCount(attachmentsArray) == 0) return nil;

    CFDictionaryRef attachments = (CFDictionaryRef)CFArrayGetValueAtIndex(attachmentsArray, 0);
    if (attachments == nil) return nil;

    // Validate the status of the frame. If it isn't `.complete`, return nil.
    CFTypeRef statusRawValue =
        CFDictionaryGetValue(attachments, (__bridge void*)SCStreamFrameInfoStatus);
    int status;
    bool result = CFNumberGetValue((CFNumberRef)statusRawValue, kCFNumberFloatType, &status);
    if (!result || status != SCFrameStatusComplete) return nil;

    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    IOSurfaceRef surface = CVPixelBufferGetIOSurface(imageBuffer);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    return surface;
}

@end
