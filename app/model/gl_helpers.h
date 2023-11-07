#import "util/log_util.h"
#import <OpenGL/gl.h>

static const char* gl_error_to_str(GLenum errorcode) {
    static const struct {
        GLenum error;
        const char* str;
    } err_to_str[] = {
        {
            GL_INVALID_ENUM,
            "GL_INVALID_ENUM",
        },
        {
            GL_INVALID_VALUE,
            "GL_INVALID_VALUE",
        },
        {
            GL_INVALID_OPERATION,
            "GL_INVALID_OPERATION",
        },
        {
            GL_INVALID_FRAMEBUFFER_OPERATION,
            "GL_INVALID_FRAMEBUFFER_OPERATION",
        },
        {
            GL_OUT_OF_MEMORY,
            "GL_OUT_OF_MEMORY",
        },
    };
    for (size_t i = 0; i < sizeof(err_to_str) / sizeof(*err_to_str); i++) {
        if (err_to_str[i].error == errorcode) return err_to_str[i].str;
    }
    return "Unknown";
}

static inline bool gl_success(const char* funcname) {
    GLenum errorcode = glGetError();
    if (errorcode != GL_NO_ERROR) {
        int attempts = 8;
        do {
            NSString* error =
                [NSString stringWithFormat:@"%s failed, glGetError returned %s(0x%X)", funcname,
                                           gl_error_to_str(errorcode), errorcode];
            log_with_type(OS_LOG_TYPE_ERROR, error, @"gl-cocoa");
            errorcode = glGetError();

            --attempts;
            if (attempts == 0) {
                log_with_type(OS_LOG_TYPE_ERROR, @"Too many GL errors, moving on", @"gl-cocoa");
                break;
            }
        } while (errorcode != GL_NO_ERROR);
        return false;
    }

    return true;
}

static inline bool gl_gen_textures(GLsizei num_texture, GLuint* textures) {
    glGenTextures(num_texture, textures);
    return gl_success("glGenTextures");
}

static inline bool gl_bind_texture(GLenum target, GLuint texture) {
    glBindTexture(target, texture);
    return gl_success("glBindTexture");
}

static inline bool gl_enable(GLenum capability) {
    glEnable(capability);
    return gl_success("glEnable");
}
