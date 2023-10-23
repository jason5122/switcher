#ifndef SHADER_H
#define SHADER_H

#import "FileUtil.hh"
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl3.h>
#include <iostream>
#include <string>

class Shader {
public:
    GLuint id;

    Shader(const std::string& vertex_path, const std::string& fragment_path) {
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

    ~Shader() {
        glDeleteProgram(id);
    }

    void use() {
        glUseProgram(id);
    }

    void set_1bool(const std::string& name, bool value) const {
        glUniform1i(glGetUniformLocation(id, name.c_str()), (int)value);
    }

    void set_1int(const std::string& name, int value) const {
        glUniform1i(glGetUniformLocation(id, name.c_str()), value);
    }

    void set_1float(const std::string& name, float value) const {
        glUniform1f(glGetUniformLocation(id, name.c_str()), value);
    }

    void set_4float(const std::string& name, float f1, float f2, float f3, float f4) const {
        glUniform4f(glGetUniformLocation(id, name.c_str()), f1, f2, f3, f4);
    }

private:
    void check_compile_errors(GLuint shader, const std::string& type) {
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
};

#endif
