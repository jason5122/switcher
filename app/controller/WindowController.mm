#import "WindowController.h"
#import "model/capture_content.h"
#import "util/log_util.h"
#import "view/CaptureView.h"
#import <vector>

struct CppMembers {
    std::vector<CaptureView*> screen_captures;
    capture_content content_engine;
};

@implementation WindowController

- (instancetype)init {
    self = [super init];
    if (self) {
        cpp = new CppMembers;
        cpp->content_engine = capture_content();
        cpp->content_engine.get_content();
        cpp->content_engine.build_window_list();

        _isShown = false;

        int count = cpp->content_engine.windows.count;

        CGFloat width = 320, height = 200;
        CGFloat padding = 20;
        NSRect windowRect =
            NSMakeRect(0, 0, (width + padding) * count + padding, height + padding * 2);
        NSRect screenCaptureRect = NSMakeRect(0, 0, width, height);

        int mask = NSWindowStyleMaskFullSizeContentView;
        window = [[NSWindow alloc] initWithContentRect:windowRect
                                             styleMask:mask
                                               backing:NSBackingStoreBuffered
                                                 defer:false];
        window.hasShadow = false;
        window.backgroundColor = NSColor.clearColor;

        NSVisualEffectView* visualEffect = [[NSVisualEffectView alloc] init];
        visualEffect.blendingMode = NSVisualEffectBlendingModeBehindWindow;
        visualEffect.material = NSVisualEffectMaterialHUDWindow;
        visualEffect.state = NSVisualEffectStateActive;

        visualEffect.wantsLayer = true;
        visualEffect.layer.cornerRadius = 9.0;

        window.contentView = visualEffect;

        for (int i = 0; i < count; i++) {
            SCWindow* capture_window = [cpp->content_engine.windows objectAtIndex:i];
            CaptureView* screenCapture = [[CaptureView alloc] initWithFrame:screenCaptureRect
                                                               targetWindow:capture_window];
            CGFloat x = padding;
            CGFloat y = padding;
            x += (width + padding) * i;
            screenCapture.frameOrigin = CGPointMake(x, y);
            [visualEffect addSubview:screenCapture];
            cpp->screen_captures.push_back(screenCapture);

            NSString* app_name = capture_window.owningApplication.applicationName;
            NSString* title = capture_window.title;
            NSString* message = [NSString stringWithFormat:@"%@ \"%@\"", title, app_name];
            log_with_type(OS_LOG_TYPE_DEFAULT, message, @"window-controller");
        }

        space = [[CGSSpace alloc] initWithLevel:1];
        [space addWindow:window];

        // TODO: experimental; consider adding/removing
        // window.ignoresMouseEvents = true;
    }
    return self;
}

- (void)showWindow {
    if (_isShown) return;
    else _isShown = true;

    for (CaptureView* screenCapture : cpp->screen_captures) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{ [screenCapture startCapture]; });
        // [screenCapture startCapture];
    }

    // actually center window
    NSSize screenSize = NSScreen.mainScreen.frame.size;
    NSSize panelSize = window.frame.size;
    CGFloat x = fmax(screenSize.width - panelSize.width, 0) * 0.5;
    CGFloat y = fmax(screenSize.height - panelSize.height, 0) * 0.5;
    window.frameOrigin = NSMakePoint(x, y);

    [window makeKeyAndOrderFront:nil];
}

- (void)hideWindow {
    if (!_isShown) return;
    else _isShown = false;

    [window orderOut:nil];

    for (CaptureView* screenCapture : cpp->screen_captures) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{ [screenCapture stopCapture]; });
    }
}

@end
