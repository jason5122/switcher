#import "WindowController.h"
#import "model/capture_content.h"
#import "util/log_util.h"
#import "view/OpenGLView.h"
#import <vector>

struct CppMembers {
    std::vector<OpenGLView*> screen_captures;
    capture_content content_engine;
};

@implementation WindowController

- (instancetype)init {
    self = [super init];
    if (self) {
        _cppMembers = new CppMembers;

        _cppMembers->content_engine = capture_content();
        _cppMembers->content_engine.build_content_list();
        NSArray<SCWindow*>* filtered_windows = _cppMembers->content_engine.get_filtered_windows();
        for (SCWindow* w in filtered_windows) {
            NSString* app_name = w.owningApplication.applicationName;
            NSString* title = w.title;
            NSString* message = [NSString stringWithFormat:@"%@ \"%@\"", title, app_name];
            log_with_type(OS_LOG_TYPE_DEFAULT, message, @"window-controller");
        }

        space = [[CGSSpace alloc] initWithLevel:1];

        // CGFloat width = 400, height = 250;
        CGFloat width = 320, height = 200;
        // CGFloat width = 200, height = 125;
        // TODO: separate into left- and right-padding
        CGFloat padding = 20;
        NSRect windowRect =
            NSMakeRect(0, 0, (width + padding) * 3 + padding, height + padding * 2);
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

        for (int i = 0; i < filtered_windows.count; i++) {
            SCWindow* capture_window = [filtered_windows objectAtIndex:i];
            OpenGLView* screenCapture = [[OpenGLView alloc] initWithFrame:screenCaptureRect
                                                             targetWindow:capture_window];
            CGFloat x = padding;
            CGFloat y = padding;
            x += (width + padding) * i;
            screenCapture.frameOrigin = CGPointMake(x, y);
            [visualEffect addSubview:screenCapture];
            _cppMembers->screen_captures.push_back(screenCapture);
        }

        // TODO: experimental; consider adding/removing
        // window.ignoresMouseEvents = true;

        // TODO: debug; remove
        // window.movableByWindowBackground = true;
    }
    return self;
}

- (void)setupWindowAndSpace {
    for (OpenGLView* screenCapture : _cppMembers->screen_captures) {
        // dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
        //                ^{ [screenCapture startCapture]; });
        [screenCapture startCapture];
    }

    // actually center window
    NSSize screenSize = NSScreen.mainScreen.frame.size;
    NSSize panelSize = window.frame.size;
    CGFloat x = fmax(screenSize.width - panelSize.width, 0) * 0.5;
    CGFloat y = fmax(screenSize.height - panelSize.height, 0) * 0.5;
    window.frameOrigin = NSMakePoint(x, y);

    // [window center];
    // [window setFrameAutosaveName:@"switcher"];
    [window makeKeyAndOrderFront:nil];

    [space addWindow:window];
}

@end
