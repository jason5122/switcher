#pragma once

#include <OpenGL/OpenGL.h>
#include <string>

class Shader {
public:
    GLuint id;

    Shader();
    ~Shader();

    void attach_vertex_shader(const std::string& vertex_path);
    void attach_fragment_shader(const std::string& fragment_path);
    void link_program();
    void use();
    void set_1bool(const std::string& name, bool value) const;
    void set_1int(const std::string& name, int value) const;
    void set_1float(const std::string& name, float value) const;
    void set_4float(const std::string& name, float f1, float f2, float f3, float f4) const;

private:
    void check_compile_errors(GLuint shader, const std::string& type);
};
