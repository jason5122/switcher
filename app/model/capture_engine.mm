#import "model/capture_engine.h"
#import "util/file_util.h"
#import "util/log_util.h"
#import "util/shader_util.h"
#import <GLKit/GLKit.h>
#import <OpenGL/gl3.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>
#import <pthread.h>

@interface ScreenCaptureDelegate : NSObject <SCStreamOutput>

@property struct screen_capture* sc;

@end

struct screen_capture {
    NSRect frame;

    SCStream* disp;
    SCStreamConfiguration* stream_config;
    SCShareableContent* shareable_content;
    ScreenCaptureDelegate* capture_delegate;

    dispatch_semaphore_t shareable_content_available;
    IOSurfaceRef current, prev;

    pthread_mutex_t mutex;

    CGWindowID window;

    NSOpenGLContext* context;
};

static NSArray* filter_content_windows(NSArray* windows) {
    NSSet* excluded_window_titles = [NSSet setWithObjects:@"Menubar", @"Item-0", nil];
    NSSet* excluded_application_names = [NSSet setWithObjects:@"Control Center", @"Dock", nil];

    return [windows
        filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(SCWindow* window,
                                                                          NSDictionary* bindings) {
          NSString* app_name = window.owningApplication.applicationName;
          NSString* title = window.title;

          if (app_name == NULL || title == NULL) return FALSE;
          if ([app_name isEqualToString:@""] || [title isEqualToString:@""]) return FALSE;

          return ![excluded_window_titles containsObject:title] &&
                 ![excluded_application_names containsObject:app_name];
        }]];
}

static bool init_screen_stream(struct screen_capture* sc) {
    SCContentFilter* content_filter;

    sc->frame = CGRectZero;
    sc->stream_config = [[SCStreamConfiguration alloc] init];
    dispatch_semaphore_wait(sc->shareable_content_available, DISPATCH_TIME_FOREVER);

    NSArray* filtered_windows = filter_content_windows(sc->shareable_content.windows);

    for (SCWindow* window in filtered_windows) {
        NSString* app_name = window.owningApplication.applicationName;
        NSString* title = window.title;
        NSString* message = [NSString stringWithFormat:@"%@ \"%@\"", title, app_name];
        log_with_type(OS_LOG_TYPE_DEFAULT, message, @"capture-engine");
    }

    __block SCWindow* target_window = nil;
    if (sc->window != 0) {
        [filtered_windows indexOfObjectPassingTest:^BOOL(SCWindow* _Nonnull window, NSUInteger idx,
                                                         BOOL* _Nonnull stop) {
          if (window.windowID == sc->window) {
              target_window = filtered_windows[idx];
              *stop = TRUE;
          }
          return *stop;
        }];
    } else {
        target_window = [filtered_windows objectAtIndex:0];
        sc->window = target_window.windowID;
    }
    content_filter = [[SCContentFilter alloc] initWithDesktopIndependentWindow:target_window];

    if (target_window) {
        [sc->stream_config setWidth:target_window.frame.size.width];
        [sc->stream_config setHeight:target_window.frame.size.height];
    }

    [sc->stream_config setQueueDepth:8];
    [sc->stream_config setShowsCursor:FALSE];
    [sc->stream_config setPixelFormat:'BGRA'];
    // [sc->stream_config setColorSpaceName:kCGColorSpaceSRGB];
    [sc->stream_config setColorSpaceName:kCGColorSpaceDisplayP3];

    sc->disp = [[SCStream alloc] initWithFilter:content_filter
                                  configuration:sc->stream_config
                                       delegate:nil];

    NSError* error = nil;
    BOOL did_add_output = [sc->disp addStreamOutput:sc->capture_delegate
                                               type:SCStreamOutputTypeScreen
                                 sampleHandlerQueue:nil
                                              error:&error];
    if (!did_add_output) {
        log_with_type(OS_LOG_TYPE_ERROR, [error localizedFailureReason], @"capture-engine");
        return !did_add_output;
    }

    dispatch_semaphore_t stream_start_completed = dispatch_semaphore_create(0);

    __block BOOL did_stream_start = false;
    [sc->disp startCaptureWithCompletionHandler:^(NSError* _Nullable error) {
      did_stream_start = (BOOL)(error == nil);
      if (!did_stream_start) {
          log_with_type(OS_LOG_TYPE_ERROR, [error localizedFailureReason], @"capture-engine");
      }
      dispatch_semaphore_signal(stream_start_completed);
    }];
    dispatch_semaphore_wait(stream_start_completed, DISPATCH_TIME_FOREVER);

    return did_stream_start;
}

static void screen_capture_build_content_list(struct screen_capture* sc) {
    typedef void (^shareable_content_callback)(SCShareableContent*, NSError*);
    shareable_content_callback new_content_received =
        ^void(SCShareableContent* shareable_content, NSError* error) {
          if (error == nil && sc->shareable_content_available != NULL) {
              sc->shareable_content = shareable_content;
          } else {
              log_with_type(
                  OS_LOG_TYPE_ERROR,
                  @"Unable to get list of available applications or windows. Please check if app"
                  @"has necessary screen capture permissions.",
                  @"capture-engine");
          }
          dispatch_semaphore_signal(sc->shareable_content_available);
        };

    dispatch_semaphore_wait(sc->shareable_content_available, DISPATCH_TIME_FOREVER);
    [SCShareableContent getShareableContentExcludingDesktopWindows:TRUE
                                               onScreenWindowsOnly:TRUE
                                                 completionHandler:new_content_received];
}

CaptureEngine::CaptureEngine(NSOpenGLContext* context) {
    sc = new screen_capture();

    sc->shareable_content_available = dispatch_semaphore_create(1);
    screen_capture_build_content_list(sc);

    sc->capture_delegate = [[ScreenCaptureDelegate alloc] init];
    sc->capture_delegate.sc = sc;

    sc->context = context;

    pthread_mutex_init(&sc->mutex, NULL);

    if (!init_screen_stream(sc)) {
        log_with_type(OS_LOG_TYPE_ERROR, @"initializing screen stream failed", @"capture-engine");
    }
}

void CaptureEngine::setup_shaders() {
    char* vsrc = read_file(resource_path("shaders/texture.vsh"));
    char* fsrc = read_file(resource_path("shaders/textureRect.fsh"));

    GLuint prog = glCreateProgram();

    GLuint vertShader = 0, fragShader = 0;
    const GLchar* vertSource = vsrc;
    const GLchar* fragSource = fsrc;
    glueCompileShader(GL_VERTEX_SHADER, 1, &vertSource, &vertShader);
    glueCompileShader(GL_FRAGMENT_SHADER, 1, &fragSource, &fragShader);
    glAttachShader(prog, vertShader);
    glAttachShader(prog, fragShader);

    // TODO: do we need this?
    glBindAttribLocation(prog, ATTRIB_VERTEX, "inVertex");
    glBindAttribLocation(prog, ATTRIB_TEXCOORD, "inTexCoord");

    glueLinkProgram(prog);

    program.uniform[UNIFORM_MVP] = glGetUniformLocation(prog, "MVP");
    program.uniform[UNIFORM_TEXTURE] = glGetUniformLocation(prog, "tex");
    program.id = prog;

    if (vertShader) glDeleteShader(vertShader);
    if (fragShader) glDeleteShader(fragShader);
    free(vsrc);
    free(fsrc);
}

void CaptureEngine::setup() {
    glGenVertexArrays(1, &quadVAOId);
    glGenBuffers(1, &quadVBOId);

    glBindVertexArray(quadVAOId);

    setup_shaders();

    glBindVertexArray(0);
}

void CaptureEngine::screen_capture_video_tick() {
    if (!sc->current) return;

    IOSurfaceRef prev_prev = sc->prev;
    if (pthread_mutex_lock(&sc->mutex)) return;
    sc->prev = sc->current;
    sc->current = NULL;
    pthread_mutex_unlock(&sc->mutex);

    if (prev_prev == sc->prev) return;

    if (prev_prev) {
        IOSurfaceDecrementUseCount(prev_prev);
        CFRelease(prev_prev);
    }
}

void CaptureEngine::screen_capture_video_render(CGRect bounds) {
    GLuint name;
    CGLContextObj cgl_ctx = sc->context.CGLContextObj;
    IOSurfaceRef surface = (IOSurfaceRef)sc->prev;

    GLsizei width = (GLsizei)IOSurfaceGetWidth(surface);
    GLsizei height = (GLsizei)IOSurfaceGetHeight(surface);

    glViewport(0, 0, width, height);
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    glGenTextures(1, &name);

    glBindTexture(GL_TEXTURE_RECTANGLE, name);
    // At the moment, CGLTexImageIOSurface2D requires the GL_TEXTURE_RECTANGLE target
    CGLTexImageIOSurface2D(cgl_ctx, GL_TEXTURE_RECTANGLE, GL_RGBA, width, height, GL_BGRA,
                           GL_UNSIGNED_INT_8_8_8_8_REV, surface, 0);
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    GLfloat logoWidth = (GLfloat)IOSurfaceGetWidth(surface) * 2;
    GLfloat logoHeight = (GLfloat)IOSurfaceGetHeight(surface) * 2;
    GLfloat quad[] = {// x, y            s, t
                      -1.0f, -1.0f, 0.0f, 0.0f,       1.0f, -1.0f, logoWidth, 0.0f,
                      -1.0f, 1.0f,  0.0f, logoHeight, 1.0f, 1.0f,  logoWidth, logoHeight};

    if (!quadInit) {
        glBindVertexArray(quadVAOId);
        glBindBuffer(GL_ARRAY_BUFFER, quadVBOId);
        glBufferData(GL_ARRAY_BUFFER, sizeof(quad), quad, GL_STATIC_DRAW);
        // positions
        glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat), NULL);
        // texture coordinates
        glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat),
                              (const GLvoid*)(2 * sizeof(GLfloat)));

        quadInit = YES;
    }

    glUseProgram(program.id);

    // const GLfloat mvp[] = {
    //     1.0f, 0.0f, 0.0f, 0.0f,  //
    //     0.0f, 1.0f, 0.0f, 0.0f,  //
    //     0.0f, 0.0f, 1.0f, 0.0f,  //
    //     0.0f, 0.0f, 0.0f, 1.0f,  //
    // };
    GLKMatrix4 mvp = GLKMatrix4Identity;
    mvp = GLKMatrix4Rotate(mvp, M_PI, 1.0, 0.0, 0.0);

    glUniformMatrix4fv(program.uniform[UNIFORM_MVP], 1, GL_FALSE, mvp.m);

    glUniform1i(program.uniform[UNIFORM_TEXTURE], 0);

    glBindTexture(GL_TEXTURE_RECTANGLE, name);
    glEnable(GL_TEXTURE_RECTANGLE);

    glBindVertexArray(quadVAOId);
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    glDisableVertexAttribArray(ATTRIB_VERTEX);
    glDisableVertexAttribArray(ATTRIB_TEXCOORD);
    glDisable(GL_TEXTURE_RECTANGLE);
}

static inline void screen_stream_video_update(struct screen_capture* sc,
                                              CMSampleBufferRef sample_buffer) {
    bool frame_detail_errored = false;
    float scale_factor = 1.0f;
    CGRect window_rect = {};

    CFArrayRef attachments_array = CMSampleBufferGetSampleAttachmentsArray(sample_buffer, false);
    if (attachments_array != NULL && CFArrayGetCount(attachments_array) > 0) {
        CFDictionaryRef attachments_dict =
            (CFDictionaryRef)CFArrayGetValueAtIndex(attachments_array, 0);
        if (attachments_dict != NULL) {
            CFTypeRef frame_scale_factor = CFDictionaryGetValue(
                attachments_dict, (__bridge void*)SCStreamFrameInfoScaleFactor);
            if (frame_scale_factor != NULL) {
                Boolean result = CFNumberGetValue((CFNumberRef)frame_scale_factor,
                                                  kCFNumberFloatType, &scale_factor);
                if (result == false) {
                    scale_factor = 1.0f;
                    frame_detail_errored = true;
                }
            }

            CFDictionaryRef content_rect_dict = (CFDictionaryRef)CFDictionaryGetValue(
                attachments_dict, (__bridge void*)SCStreamFrameInfoContentRect);
            CFNumberRef content_scale_factor = (CFNumberRef)CFDictionaryGetValue(
                attachments_dict, (__bridge void*)SCStreamFrameInfoContentScale);
            if (content_rect_dict != NULL && content_scale_factor != NULL) {
                CGRect content_rect = {};
                float points_to_pixels = 0.0f;

                Boolean result =
                    CGRectMakeWithDictionaryRepresentation(content_rect_dict, &content_rect);
                if (result == false) {
                    content_rect = CGRectZero;
                    frame_detail_errored = true;
                }
                result =
                    CFNumberGetValue(content_scale_factor, kCFNumberFloatType, &points_to_pixels);
                if (result == false) {
                    points_to_pixels = 1.0f;
                    frame_detail_errored = true;
                }

                window_rect.origin = content_rect.origin;
                window_rect.size.width = content_rect.size.width / points_to_pixels * scale_factor;
                window_rect.size.height =
                    content_rect.size.height / points_to_pixels * scale_factor;
            }
        }
    }

    CVImageBufferRef image_buffer = CMSampleBufferGetImageBuffer(sample_buffer);

    CVPixelBufferLockBaseAddress(image_buffer, 0);
    IOSurfaceRef frame_surface = CVPixelBufferGetIOSurface(image_buffer);
    CVPixelBufferUnlockBaseAddress(image_buffer, 0);

    IOSurfaceRef prev_current = NULL;

    if (frame_surface && !pthread_mutex_lock(&sc->mutex)) {
        bool needs_to_update_properties = false;

        if (!frame_detail_errored) {
            if ((sc->frame.size.width != window_rect.size.width) ||
                (sc->frame.size.height != window_rect.size.height)) {
                sc->frame.size.width = window_rect.size.width;
                sc->frame.size.height = window_rect.size.height;
                needs_to_update_properties = true;
            }
        }

        if (needs_to_update_properties) {
            [sc->stream_config setWidth:sc->frame.size.width];
            [sc->stream_config setHeight:sc->frame.size.height];

            [sc->disp updateConfiguration:sc->stream_config
                        completionHandler:^(NSError* _Nullable error) {
                          if (error) {
                              log_with_type(OS_LOG_TYPE_ERROR, [error localizedFailureReason],
                                            @"capture-engine");
                          }
                        }];
        }

        prev_current = sc->current;
        sc->current = frame_surface;
        CFRetain(sc->current);
        IOSurfaceIncrementUseCount(sc->current);

        pthread_mutex_unlock(&sc->mutex);
    }

    if (prev_current) {
        IOSurfaceDecrementUseCount(prev_current);
        CFRelease(prev_current);
    }
}

@implementation ScreenCaptureDelegate

- (void)stream:(SCStream*)stream
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
                   ofType:(SCStreamOutputType)type {
    if (type == SCStreamOutputTypeScreen) {
        screen_stream_video_update(self.sc, sampleBuffer);
    }
}

@end
