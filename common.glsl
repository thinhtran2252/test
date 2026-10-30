#ifndef COMMON_INC
#define COMMON_INC

#include "uniforms.glsl"

const float PI = 3.14159265;
const float INV_PI = 0.31830988618;

const vec3 blocklight_colour = vec3(0.9765, 0.7922, 0.5765);

vec3 sRGBToLinear(vec3 rgb)
{
    #ifdef FAST_LINEAR_SRGB
        return pow(rgb, vec3(2.2));
    #else
        return mix(
            pow((rgb + 0.055) * (1.0 / 1.055), vec3(2.4)),
            rgb * (1.0 / 12.92),
            vec3(lessThanEqual(rgb, vec3(0.04045)))
        );
    #endif
}

vec3 LinearToSRGB(vec3 rgb)
{
    #ifdef FAST_LINEAR_SRGB
        return pow(rgb, vec3(0.4545454545));
    #else
        return mix(
            1.055 * pow(rgb, vec3(1.0 / 2.4)) - 0.055,
            rgb * 12.92,
            vec3(lessThanEqual(rgb, vec3(0.0031308)))
        );
    #endif
}

vec3 LightPosToWorldDir(vec3 light_pos)
{
    return normalize(light_pos * mat3(gbufferModelView));
}

vec3 TransformScreenToViewPoint(vec3 screen_point)
{
    vec3 clip_point = screen_point * 2.0 - 1.0;
    vec4 view_point = gbufferProjectionInverse * vec4(clip_point, 1.0);
    return view_point.xyz / view_point.w;
}

vec3 TransformViewToWorldPoint(vec3 view_point)
{
    return (gbufferModelViewInverse * vec4(view_point, 0.0)).xyz + cameraPosition;
}

vec3 TransformScreenToWorldPoint(vec3 screen_point)
{
    vec3 clip_point = screen_point * 2.0 - 1.0;
    vec4 view_point = gbufferProjectionInverse * vec4(clip_point, 1.0);
    view_point.xyz /= view_point.w;
    return (gbufferModelViewInverse * vec4(view_point.xyz, 1.0)).xyz;
}

float LinearizeDepth(float depth, float near_plane, float far_plane)
{
    return (near_plane * far_plane) / (depth * (near_plane - far_plane) + far_plane);
}

float DelinearizeDepth(float linearDepth, float near_plane, float far_plane)
{
    return (far_plane * (near_plane - linearDepth)) / (linearDepth * (near_plane - far_plane));
}

#endif
