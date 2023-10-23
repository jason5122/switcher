#ifndef BOING_RENDERER_H
#define BOING_RENDERER_H

#import "FileUtil.hh"
#import "Shader.hpp"

class Renderer {
    GLuint VBO, VAO;
    Shader* shader;

public:
    Renderer();
    ~Renderer();
    void render(float width, float height);
};

#endif
