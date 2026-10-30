// Distant Horizons programs must use the compatibility profile explicitly -
// they don't share lib/version.glsl's plain #version 120 with the rest of
// the pack.
#version 150 compatibility

#include "lib/uniforms.glsl"
#include "lib/common.glsl"

varying vec2 lmcoord;
varying vec4 glcolour;
varying float v_sky_light;

void main()
{
    gl_Position = ftransform();

    // DH's vertex layout only exposes gl_MultiTexCoord2 for lightmap data,
    // not gl_MultiTexCoord1 like normal terrain.
    lmcoord  = (gl_TextureMatrix[2] * gl_MultiTexCoord2).xy;
    glcolour = gl_Color;

    // Same result for every fragment in the frame, so compute it once per
    // vertex here instead of once per fragment.
    vec3 sun_direction = LightPosToWorldDir(sunPosition);
    v_sky_light = pow(sun_direction.y * 0.5 + 0.5, 3.0);
    v_sky_light *= (1.0 - rainStrength) * 0.1 + 0.9;
}
