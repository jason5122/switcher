#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>

// TODO: temporary, maybe remove if unnecessary?
struct gs_texture {
    // gs_device_t* device;
    GLenum gl_format;
    GLenum gl_target;
    GLenum gl_internal_format;
    GLenum gl_type;
    GLuint texture;
    uint32_t levels;

    // gs_samplerstate_t* cur_sampler;
    struct fbo_info* fbo;
};

// struct gs_effect {
//     bool processing;
//     bool cached;
//     char *effect_path, *effect_dir;

//     DARRAY(struct gs_effect_param) params;
//     DARRAY(struct gs_effect_technique) techniques;

//     struct gs_effect_technique* cur_technique;
//     struct gs_effect_pass* cur_pass;

//     // gs_eparam_t *view_proj, *world, *scale;
//     // graphics_t* graphics;

//     struct gs_effect* next;

//     size_t loop_pass;
//     bool looping;
// };

typedef struct gs_texture gs_texture_t;
// typedef struct gs_effect gs_effect_t;

gs_texture_t* gs_texture_create_from_iosurface(void* iosurf);

bool gs_texture_rebind_iosurface(gs_texture_t* texture, void* iosurf);
