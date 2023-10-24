#pragma once

#import "Shader.hpp"
#import <OpenGL/OpenGL.h>

class Renderer {
    GLuint VBO, VAO;
    Shader* shader;

public:
    Renderer();
    ~Renderer();
    void render(float width, float height);
};
