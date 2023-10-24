#include "FileUtil.h"
#include "LogUtil.h"
#include "Shader.hpp"
#include <OpenGL/gl3.h>
#include <string>

Shader::Shader(const std::string& vertex_path, const std::string& fragment_path) {
    const char* vsrc = read_file(resource_path(vertex_path.c_str()));
    const char* fsrc = read_file(resource_path(fragment_path.c_str()));

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
    int len;
    std::string message;
    if (type != "PROGRAM") {
        glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &len);
        if (!success) {
            message.resize(len);
            glGetShaderInfoLog(shader, 1024, NULL, &message[0]);
            message = "shader compilation error: " + message;
        }
    } else {
        glGetProgramiv(shader, GL_LINK_STATUS, &success);
        glGetProgramiv(shader, GL_INFO_LOG_LENGTH, &len);
        if (!success) {
            message.resize(len);
            glGetProgramInfoLog(shader, 1024, NULL, &message[0]);
            message = "program linking error: " + message;
        }
    }

    if (!success) {
        log_error(message.c_str(), "Shader.cpp");
    }
}
