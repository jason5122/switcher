#pragma once

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl3.h>

GLint glueCompileShader(GLenum target, GLsizei count, const GLchar** sources, GLuint* shader);
GLint glueLinkProgram(GLuint program);
