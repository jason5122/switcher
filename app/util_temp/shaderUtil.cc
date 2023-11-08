#include "shaderUtil.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#define LogInfo printf
#define LogError printf

/* Compile a shader from the provided source(s) */
GLint glueCompileShader(GLenum target, GLsizei count, const GLchar** sources, GLuint* shader) {
	GLint logLength, status;

	*shader = glCreateShader(target);
	glShaderSource(*shader, count, sources, NULL);
	glCompileShader(*shader);
	glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0) {
		GLchar* log = (GLchar*)malloc(logLength);
		glGetShaderInfoLog(*shader, logLength, &logLength, log);
		LogInfo("Shader compile log:\n%s", log);
		free(log);
	}

	glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
	if (status == 0) {
		int i;

		LogError("Failed to compile shader:\n");
		for (i = 0; i < count; i++) LogInfo("%s", sources[i]);
	}

	return status;
}

/* Link a program with all currently attached shaders */
GLint glueLinkProgram(GLuint program) {
	GLint logLength, status;

	glLinkProgram(program);
	glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0) {
		GLchar* log = (GLchar*)malloc(logLength);
		glGetProgramInfoLog(program, logLength, &logLength, log);
		LogInfo("Program link log:\n%s", log);
		free(log);
	}

	glGetProgramiv(program, GL_LINK_STATUS, &status);
	if (status == 0) LogError("Failed to link program %d", program);

	return status;
}

/* Validate a program (for i.e. inconsistent samplers) */
GLint glueValidateProgram(GLuint program) {
	GLint logLength, status;

	glValidateProgram(program);
	glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0) {
		GLchar* log = (GLchar*)malloc(logLength);
		glGetProgramInfoLog(program, logLength, &logLength, log);
		LogInfo("Program validate log:\n%s", log);
		free(log);
	}

	glGetProgramiv(program, GL_VALIDATE_STATUS, &status);
	if (status == 0) LogError("Failed to validate program %d", program);

	return status;
}

/* Return named uniform location after linking */
GLint glueGetUniformLocation(GLuint program, const GLchar* uniformName) {
	GLint loc;

	loc = glGetUniformLocation(program, uniformName);

	return loc;
}

/* Convenience wrapper that compiles, links, enumerates uniforms and attribs */
GLint glueCreateProgram(GLsizei attribNameCt, const GLchar** attribNames,
                        const GLint* attribLocations, GLsizei uniformNameCt,
                        const GLchar** uniformNames, GLint* uniformLocations, GLuint* program,
                        GLuint prog) {
	GLuint status = 1, i;

	for (i = 0; i < attribNameCt; i++) {
		if (strlen(attribNames[i])) glBindAttribLocation(prog, attribLocations[i], attribNames[i]);
	}

	glueLinkProgram(prog);
	glueValidateProgram(prog);

	if (status) {
		for (i = 0; i < uniformNameCt; i++) {
			if (strlen(uniformNames[i]))
				uniformLocations[i] = glueGetUniformLocation(prog, uniformNames[i]);
		}
		*program = prog;
	}

	return status;
}
