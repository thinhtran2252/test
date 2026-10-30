#include "lib/version.glsl"

varying vec4 star_data;

void main()
{
    gl_Position = ftransform();
    star_data = vec4(gl_Color.rgb, float(gl_Color.r == gl_Color.g && gl_Color.g == gl_Color.b && gl_Color.r > 0.0));
}
