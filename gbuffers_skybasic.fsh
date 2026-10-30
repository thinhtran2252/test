#include "lib/version.glsl"

#include "lib/uniforms.glsl"
#include "lib/common.glsl"

varying vec4 star_data;

float AddFog(float x, float w)
{
    return w / (x * x + w);
}

vec3 CalculateSkyColor(vec3 pos)
{
    float upDot = dot(pos, gbufferModelView[1].xyz);
    return mix(skyColor, fogColor, AddFog(max(upDot, 0.0), 0.25));
}

void main()
{
    vec4 colour = vec4(0.0);
    vec3 pos = TransformScreenToViewPoint(vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), 1.0));

    if (star_data.a > 0.5)
    {
        colour = vec4(star_data.rgb, 1.0);
    }
    else
    {
        vec3 albedo = sRGBToLinear(CalculateSkyColor(normalize(pos)));
        colour = vec4(albedo, 1.0);
    }

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = colour;
}
