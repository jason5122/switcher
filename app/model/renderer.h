#pragma once

#import "model/shader.h"
#import <OpenGL/OpenGL.h>

class Renderer {
    GLuint VBO, VAO;
    Shader* shader;

public:
    Renderer();
    ~Renderer();
    void render(float width, float height);
};
