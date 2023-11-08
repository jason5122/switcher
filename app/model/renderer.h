#pragma once

#import "model/shader.h"
#import <OpenGL/gl3.h>

class Renderer {
    GLuint VBO, VAO;
    Shader shader;

public:
    Renderer();
    ~Renderer();
    void render(float width, float height);
};
