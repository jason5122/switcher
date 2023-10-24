#import "FileUtil.h"
#include "Shader.hpp"
#import <OpenGL/gl3.h>
#import <iostream>

Shader::Shader(const std::string& vertex_path, const std::string& fragment_path) {
    char* vsrc = read_file(resource_path(vertex_path));
    char* fsrc = read_file(resource_path(fragment_path));

    GLuint vertex, fragment;

    vertex = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertex, 1, &vsrc, NULL);
    glCompileShader(vertex);
    check_compile_errors(vertex, "VERTEX");

    fragment = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragment, 1, &fsrc, NULL);
    glCompileShader(fragment);
    check_compile_errors(fragment, "FRAGMENT");

    id = glCreateProgram();
    glAttachShader(id, vertex);
    glAttachShader(id, fragment);
    glLinkProgram(id);
    check_compile_errors(id, "PROGRAM");

    glDeleteShader(vertex);
    glDeleteShader(fragment);
}

Shader::~Shader() {
    glDeleteProgram(id);
}

void Shader::use() {
    glUseProgram(id);
}

void Shader::set_1bool(const std::string& name, bool value) const {
    glUniform1i(glGetUniformLocation(id, name.c_str()), (int)value);
}

void Shader::set_1int(const std::string& name, int value) const {
    glUniform1i(glGetUniformLocation(id, name.c_str()), value);
}

void Shader::set_1float(const std::string& name, float value) const {
    glUniform1f(glGetUniformLocation(id, name.c_str()), value);
}

void Shader::set_4float(const std::string& name, float f1, float f2, float f3, float f4) const {
    glUniform4f(glGetUniformLocation(id, name.c_str()), f1, f2, f3, f4);
}

void Shader::check_compile_errors(GLuint shader, const std::string& type) {
    int success;
    char infoLog[1024];
    if (type != "PROGRAM") {
        glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
        if (!success) {
            glGetShaderInfoLog(shader, 1024, NULL, infoLog);
            std::cout << "ERROR::SHADER_COMPILATION_ERROR of type: " << type << "\n"
                      << infoLog
                      << "\n -- "
                         "------------------------------------------------"
                         "--- -- "
                      << std::endl;
        }
    } else {
        glGetProgramiv(shader, GL_LINK_STATUS, &success);
        if (!success) {
            glGetProgramInfoLog(shader, 1024, NULL, infoLog);
            std::cout << "ERROR::PROGRAM_LINKING_ERROR of type: " << type << "\n"
                      << infoLog
                      << "\n -- "
                         "------------------------------------------------"
                         "--- -- "
                      << std::endl;
        }
    }
}
