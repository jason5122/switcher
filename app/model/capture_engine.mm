#import "gl_helpers.h"
#import "model/capture_engine.h"
#import "util/log_util.h"
#import <ScreenCaptureKit/ScreenCaptureKit.h>
#include <pthread.h>

#include "util_temp/fileUtil.h"
#include "util_temp/shaderUtil.h"
#import <GLKit/GLKit.h>
#import <OpenGL/gl3.h>

@interface ScreenCaptureDelegate : NSObject <SCStreamOutput>

@property struct screen_capture* sc;

@end

struct screen_capture {
    gs_texture_t* tex;

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
    [sc->stream_config setColorSpaceName:kCGColorSpaceSRGB];

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

CaptureEngine::CaptureEngine(NSOpenGLContext* context, GLuint texture) {
    this->texture = texture;  // TODO: remove this

    // shader.attach_vertex_shader("shaders/triangle.vs");
    shader.attach_fragment_shader("shaders/simple.fs");

    shader.link_program();

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

void CaptureEngine::draw1() {
    // 1. Create a texture from the IOSurface
    GLuint texture;
    IOSurfaceRef surface = (IOSurfaceRef)sc->prev;
    GLsizei surface_w = (GLsizei)IOSurfaceGetWidth(surface);
    GLsizei surface_h = (GLsizei)IOSurfaceGetHeight(surface);
    {
        CGLContextObj cgl_ctx = sc->context.CGLContextObj;

        glGenTextures(1, &texture);

        glBindTexture(GL_TEXTURE_RECTANGLE_EXT, texture);

        CGLError err =
            CGLTexImageIOSurface2D(cgl_ctx, GL_TEXTURE_RECTANGLE_EXT, GL_RGBA, surface_w,
                                   surface_h, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, surface, 0);

        if (err != kCGLNoError) {
            log_with_type(OS_LOG_TYPE_ERROR, @"CGLTexImageIOSurface2D error", @"capture-engine");
        }

        glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
    }

    GLubyte* pixelData = (GLubyte*)calloc(TEXTURE_WIDTH * TEXTURE_HEIGHT * 4, sizeof(GLubyte));
    glGetTexImage(GL_TEXTURE_RECTANGLE_EXT, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, pixelData);
    NSData* data = [[NSData alloc] initWithBytes:pixelData length:50000];
    log_with_type(OS_LOG_TYPE_DEFAULT, data.description, @"capture-engine");

    // 2. Draw the texture to the current OpenGL context
    // {
    //     glBindTexture(GL_TEXTURE_RECTANGLE_EXT, texture);
    //     glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    //     glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    //     glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);

    //     glBegin(GL_QUADS);

    //     glColor4f(0.f, 0.f, 1.0f, 1.0f);
    //     glTexCoord2f(0, 0);
    //     glVertex2f(0, 0);

    //     glTexCoord2f(1728, 0);
    //     glVertex2f(1728, 0);

    //     glTexCoord2f(1728, 1117);
    //     glVertex2f(1728, 1117);

    //     glTexCoord2f(0, 1117);
    //     glVertex2f(0, 1117);

    //     glDrawArrays(GL_QUADS, 0, 4);

    //     glEnd();

    //     glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
    // }
    // glDeleteTextures(1, &texture);

    draw2();
}

void CaptureEngine::draw2() {
    const GLfloat vertices[12] = {1, -1, -1, 1, 1, -1, -1, 1, -1, -1, -1, -1};

    // Rectangle textures require non-normalized texture coordinates
    const GLfloat texcoords[] = {
        0, 0, 0, TEXTURE_HEIGHT, TEXTURE_WIDTH, TEXTURE_HEIGHT, TEXTURE_WIDTH, 0,
    };

    CGLLockContext(sc->context.CGLContextObj);
    [sc->context makeCurrentContext];

    glTexCoordPointer(2, GL_FLOAT, 0, texcoords);
    glBindTexture(GL_TEXTURE_RECTANGLE_EXT, texture);

    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glDrawArrays(GL_QUADS, 0, 4);

    glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
}

void CaptureEngine::draw3() {
    if (!sc->prev) return;

    glEnable(GL_TEXTURE_RECTANGLE_ARB);

    GLuint texture;
    IOSurfaceRef surface = (IOSurfaceRef)sc->prev;
    GLsizei surface_w = (GLsizei)IOSurfaceGetWidth(surface);
    GLsizei surface_h = (GLsizei)IOSurfaceGetHeight(surface);

    CGLContextObj cgl_ctx = sc->context.CGLContextObj;

    glGenTextures(1, &texture);

    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, texture);

    CGLTexImageIOSurface2D(cgl_ctx, GL_TEXTURE_RECTANGLE_ARB, GL_RGBA, surface_w, surface_h,
                           GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, surface, 0);

    glTexParameteri(texture, GL_TEXTURE_MAX_LEVEL, 0);

    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);

    GLubyte* pixelData = (GLubyte*)calloc(TEXTURE_WIDTH * TEXTURE_HEIGHT * 4, sizeof(GLubyte));
    glGetTexImage(GL_TEXTURE_RECTANGLE_ARB, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, pixelData);
    NSData* data = [[NSData alloc] initWithBytes:pixelData length:50000];
    log_with_type(OS_LOG_TYPE_DEFAULT, data.description, @"capture-engine");

    // GLuint vao;
    // glGenVertexArrays(1, &vao);
    // glBindVertexArray(vao);

    // shader.use();
    // glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

enum { PROGRAM_TEXTURE_RECT, NUM_PROGRAMS };

enum { UNIFORM_MVP, UNIFORM_TEXTURE, NUM_UNIFORMS };

enum { ATTRIB_VERTEX, ATTRIB_TEXCOORD, NUM_ATTRIBS };

typedef struct {
    char *vert, *frag;
    GLint uniform[NUM_UNIFORMS];
    GLuint id;
} programInfo_t;

programInfo_t program[NUM_PROGRAMS] = {
    {(char*)"shaders/texture.vsh", (char*)"shaders/textureRect.fsh"},  // PROGRAM_TEXTURE_RECT
};

void setupShaders() {
    for (int i = 0; i < NUM_PROGRAMS; i++) {
        char* vsrc = readFile(pathForResource(program[i].vert));
        char* fsrc = readFile(pathForResource(program[i].frag));
        GLsizei attribCt = 0;
        GLchar* attribUsed[NUM_ATTRIBS];
        GLint attrib[NUM_ATTRIBS];
        GLchar* attribName[NUM_ATTRIBS] = {
            (char*)"inVertex",
            (char*)"inTexCoord",
        };
        const GLchar* uniformName[NUM_UNIFORMS] = {
            (char*)"MVP",
            (char*)"tex",
        };

        // auto-assign known attribs
        for (int j = 0; j < NUM_ATTRIBS; j++) {
            if (strstr(vsrc, attribName[j])) {
                attrib[attribCt] = j;
                attribUsed[attribCt++] = attribName[j];
            }
        }

        glueCreateProgram(vsrc, fsrc, attribCt, (const GLchar**)&attribUsed[0], attrib,
                          NUM_UNIFORMS, &uniformName[0], program[i].uniform, &program[i].id);
        free(vsrc);
        free(fsrc);
    }
}

void CaptureEngine::setup1() {
    glGenVertexArrays(1, &quadVAOId);
    glGenBuffers(1, &quadVBOId);

    glBindVertexArray(quadVAOId);

    setupShaders();

    glBindVertexArray(0);
}

void CaptureEngine::draw4(CGRect bounds) {
    GLuint name;
    CGLContextObj cgl_ctx = sc->context.CGLContextObj;
    IOSurfaceRef surface = (IOSurfaceRef)sc->prev;

    GLsizei width = (GLsizei)IOSurfaceGetWidth(surface);
    GLsizei height = (GLsizei)IOSurfaceGetHeight(surface);

    glGenTextures(1, &name);

    glBindTexture(GL_TEXTURE_RECTANGLE, name);
    // At the moment, CGLTexImageIOSurface2D requires the GL_TEXTURE_RECTANGLE target
    CGLTexImageIOSurface2D(cgl_ctx, GL_TEXTURE_RECTANGLE, GL_RGBA, width, height, GL_BGRA,
                           GL_UNSIGNED_INT_8_8_8_8_REV, surface, 0);
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    GLfloat logoWidth = (GLfloat)IOSurfaceGetWidth(surface);
    GLfloat logoHeight = (GLfloat)IOSurfaceGetHeight(surface);
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

    glUseProgram(program[PROGRAM_TEXTURE_RECT].id);

    // projection matrix
    GLfloat aspectRatio = bounds.size.width / bounds.size.height;
    GLKMatrix4 projection = GLKMatrix4MakeFrustum(-aspectRatio, aspectRatio, -1, 1, 2, 100);
    // modelView matrix
    GLKMatrix4 modelView = GLKMatrix4MakeTranslation(0, 0, -9.0);
    modelView = GLKMatrix4Scale(modelView, 2.5, 2.5, 2.5);
    modelView = GLKMatrix4Rotate(modelView, 30.0 * M_PI / 180.0, 0.0, 1.0, 0.0);

    GLKMatrix4 mvp = GLKMatrix4Multiply(projection, modelView);
    glUniformMatrix4fv(program[PROGRAM_TEXTURE_RECT].uniform[UNIFORM_MVP], 1, GL_FALSE, mvp.m);

    glUniform1i(program[PROGRAM_TEXTURE_RECT].uniform[UNIFORM_TEXTURE], 0);

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

void CaptureEngine::screen_capture_video_tick() {
    if (!sc->current) return;

    IOSurfaceRef prev_prev = sc->prev;
    if (pthread_mutex_lock(&sc->mutex)) return;
    sc->prev = sc->current;
    sc->current = NULL;
    pthread_mutex_unlock(&sc->mutex);

    if (prev_prev == sc->prev) return;

    CGLLockContext(sc->context.CGLContextObj);
    [sc->context makeCurrentContext];

    // if (sc->tex) gs_texture_rebind_iosurface(sc->tex, sc->prev);
    // else sc->tex = gs_texture_create_from_iosurface(sc->prev);

    // [sc->context flushBuffer];
    CGLUnlockContext(sc->context.CGLContextObj);

    if (prev_prev) {
        IOSurfaceDecrementUseCount(prev_prev);
        CFRelease(prev_prev);
    }
}

void CaptureEngine::screen_capture_video_render() {
    draw1();
    // draw2();
}

static inline void screen_stream_video_update(struct screen_capture* sc,
                                              CMSampleBufferRef sample_buffer) {
    // log_with_type(OS_LOG_TYPE_DEFAULT, @"screen update", @"capture-engine");

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
