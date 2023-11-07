#import "gl_cocoa.h"
#import "gl_helpers.h"
#import "util/log_util.h"

gs_texture_t* gs_texture_create_from_iosurface(void* iosurf) {
    IOSurfaceRef ref = (IOSurfaceRef)iosurf;

    gs_texture_t* tex = (gs_texture_t*)malloc(sizeof(gs_texture_t));

    OSType pf = IOSurfaceGetPixelFormat(ref);
    if (pf == 0) {
        log_with_type(OS_LOG_TYPE_ERROR, @"Invalid IOSurface Buffer", @"gl-cocoa");
    } else if (pf != 'BGRA') {
        NSString* pf_string = [NSString stringWithFormat:@"Unexpected pixel format: %d (%c%c%c%c)",
                                                         pf, pf >> 24, pf >> 16, pf >> 8, pf];
        log_with_type(OS_LOG_TYPE_ERROR, pf_string, @"gl-cocoa");
    }

    tex->gl_format = GL_BGRA;
    tex->gl_target = GL_TEXTURE_RECTANGLE_ARB;
    tex->gl_internal_format = GL_SRGB8_ALPHA8;
    tex->gl_type = GL_UNSIGNED_INT_8_8_8_8_REV;

    if (!gl_gen_textures(1, &tex->texture)) goto fail;
    if (!gl_bind_texture(tex->gl_target, tex->texture)) goto fail;

    return tex;

fail:
    if (tex->texture) glDeleteTextures(1, &tex->texture);
    log_with_type(OS_LOG_TYPE_ERROR, @"device_texture_create_from_iosurface (GL) failed",
                  @"gl-cocoa");
    return NULL;
}

bool gs_texture_rebind_iosurface(gs_texture_t* tex, void* iosurf) {
    if (!tex) return false;
    if (!iosurf) return false;

    IOSurfaceRef ref = (IOSurfaceRef)iosurf;

    OSType pf = IOSurfaceGetPixelFormat(ref);
    if (pf == 0) {
        log_with_type(OS_LOG_TYPE_ERROR, @"Invalid IOSurface Buffer", @"gl-cocoa");
    } else if (pf != 'BGRA') {
        NSString* msg = [NSString stringWithFormat:@"Unexpected pixel format: %d (%c%c%c%c)", pf,
                                                   pf >> 24, pf >> 16, pf >> 8, pf];
        log_with_type(OS_LOG_TYPE_ERROR, msg, @"gl-cocoa");
    }

    uint32_t width = IOSurfaceGetWidth(ref);
    uint32_t height = IOSurfaceGetHeight(ref);

    if (!gl_bind_texture(tex->gl_target, tex->texture)) return false;

    CGLError err = CGLTexImageIOSurface2D([[NSOpenGLContext currentContext] CGLContextObj],
                                          tex->gl_target, tex->gl_internal_format, width, height,
                                          tex->gl_format, tex->gl_type, ref, 0);

    if (err != kCGLNoError) {
        NSString* msg = [NSString stringWithFormat:@"CGLTexImageIOSurface2D: %u, %s"
                                                    " (gs_texture_rebind_iosurface)",
                                                   err, CGLErrorString(err)];
        log_with_type(OS_LOG_TYPE_ERROR, msg, @"gl-cocoa");

        gl_success("CGLTexImageIOSurface2D");
        return false;
    }

    if (!gl_bind_texture(tex->gl_target, 0)) return false;

    return true;
}
