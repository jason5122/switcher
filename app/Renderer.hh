#ifndef BOING_RENDERER_H
#define BOING_RENDERER_H

#import "FileUtil.hh"
#import "Shader.hpp"
#import <iostream>
#import <map>
#import <string>

#include "stb_image.h"
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>

// #include <ft2build.h>
// #include FT_FREETYPE_H

struct Character {
    unsigned int texture_id;  // ID handle of the glyph texture
    glm::ivec2 size;          // Size of glyph
    glm::ivec2 bearing;       // Offset from baseline to left/top of glyph
    unsigned int advance;     // Horizontal offset to advance to next glyph
};

class Renderer {
    GLuint VBO, VAO;
    GLuint texture1, texture2;
    Shader* shader;
    float elapsed_time = 0.0f;
    uint64_t prev_time = clock_gettime_nsec_np(CLOCK_MONOTONIC);

    Shader* text_shader;
    GLuint text_vbo, text_vao;
    std::map<GLchar, Character> characters;

public:
    float x = 0.0f;
    float y = 0.0f;
    float z = -5.0f;
    bool can_rotate = true;

    Renderer();
    ~Renderer();
    void render(float width, float height);
};

#endif
