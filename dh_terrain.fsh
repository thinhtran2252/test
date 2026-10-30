// Distant Horizons programs must use the compatibility profile explicitly.
#version 150 compatibility

#include "lib/uniforms.glsl"
#include "lib/common.glsl"

varying vec2 lmcoord;
varying vec4 glcolour;
varying float v_sky_light;

void main()
{
    vec4 result = glcolour;

    if (result.a < 0.1)
    {
        discard;
    }

    result.rgb = sRGBToLinear(result.rgb);

    vec3 screen_point = gl_FragCoord.xyz / vec3(viewWidth, viewHeight, 1.0);
    vec3 world_point = TransformScreenToWorldPoint(screen_point) * float(dhRenderDistance);
    float dist_to_player = length(world_point);

    vec2 screen_coord = screen_point.xy;
    float depth = texture2D(depthtex0, screen_coord).x;
    float linear_depth = LinearizeDepth(depth, near, far * 4.0);
    float dh_depth = gl_FragCoord.z;
    float linear_dh_depth = LinearizeDepth(dh_depth, dhNearPlane, dhFarPlane);

    if (linear_depth < linear_dh_depth && depth < 1.0)
    {
        discard;
    }

    result.rgb *= v_sky_light;

    float max_fog_dist = dhFarPlane;
    max_fog_dist = (isEyeInWater == 2 ? 3.0 : isEyeInWater == 1 ? 10.0 : max_fog_dist);
    max_fog_dist /= FOG_DENSITY;

    float fog = dist_to_player / max_fog_dist;
    vec3 fog_col = mix(vec3(0.0), fogColor, float(eyeBrightnessSmooth.y) / 240.0);
    result.rgb = mix(result.rgb, sRGBToLinear(fog_col), smoothstep(0.0, 1.0, min(1.0, fog)));

    float dh_blend = smoothstep(0.0, 1.0, dist_to_player);

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(result.rgb, mix(0.0, result.a, dh_blend));
}
