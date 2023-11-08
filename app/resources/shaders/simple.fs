#version 120
uniform sampler2DRect texture;
varying vec2 texCoord;
uniform vec2 size;

void main() {
    vec4 tex = texture2DRect(texture, texCoord * size);
    gl_FragColor = tex;
}
