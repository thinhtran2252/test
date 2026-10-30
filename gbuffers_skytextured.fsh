#include "lib/version.glsl"

varying vec2 texcoord;

#include "lib/uniforms.glsl"
#include "lib/common.glsl"

void main()
{
    vec4 colour = texture2D(gtexture, texcoord);
    if (colour.a < 0.1) discard;

    colour.rgb = sRGBToLinear(colour.rgb);

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = colour;
}
