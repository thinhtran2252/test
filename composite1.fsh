#include "lib/version.glsl"

varying vec2 texcoord;

#include "lib/uniforms.glsl"
#include "lib/common.glsl"

vec3 YUVToRGB(vec3 yuv)
{
    float y = yuv.x;
    float u = yuv.y;
    float v = yuv.z;

    return vec3(
        y + 1.0 / 0.877 * v,
        y - 0.39393 * u - 0.58081 * v,
        y + 1.0 / 0.493 * u
    );
}

// Manual box blur standing in for a mip-level sample. Avoids relying on
// hardware-generated mipmaps on a render-target texture, which can hang
// on some mobile/translation-layer GL drivers. 3x3 taps keeps this cheap
// on weaker GPUs - noticeably faster than a wider kernel with very little
// visible difference for this effect.
vec3 BoxBlur(sampler2D tex, vec2 uv, float radius, vec2 texel)
{
    if (radius < 0.001) return texture2D(tex, uv).rgb;

    const int TAPS = 3;
    vec3 sum = vec3(0.0);

    for (int x = 0; x < TAPS; x++)
    {
        for (int y = 0; y < TAPS; y++)
        {
            vec2 offset = (vec2(x, y) - float(TAPS - 1) * 0.5) * radius * texel;
            sum += texture2D(tex, uv + offset).rgb;
        }
    }

    return sum / float(TAPS * TAPS);
}

void main()
{
    vec4 colour = texture2D(colortex0, texcoord);
    vec2 texel = 1.0 / vec2(viewWidth, viewHeight);

    // Blur luma and chroma by different amounts to emulate the reduced
    // bandwidth of the chroma channels on an analog composite signal.
    // Linear scaling here (not exp2) keeps the higher quality settings
    // from turning the whole image into mush.
    float luma_radius = LUMA_QUALITY;
    float chroma_radius = CHROMA_QUALITY * 1.5;

    // One blur at whichever radius is larger, then mix each channel in
    // from it proportionally to its own radius - same result as two full
    // blurs in the common case (chroma radius >= luma radius), at half
    // the texture fetches. This runs on every pixel every frame with no
    // way to disable it, so it's worth the extra care.
    float max_radius = max(luma_radius, chroma_radius);
    vec3 blurred = BoxBlur(colortex0, texcoord, max_radius, texel);

    float luma_t = max_radius > 0.001 ? clamp(luma_radius / max_radius, 0.0, 1.0) : 0.0;
    float chroma_t = max_radius > 0.001 ? clamp(chroma_radius / max_radius, 0.0, 1.0) : 0.0;

    float luma = mix(colour.r, blurred.r, luma_t);
    vec2 chroma = mix(colour.gb, blurred.gb, chroma_t);

    // Undo the +0.5 storage offset from composite.fsh before decoding.
    chroma -= 0.5;

    colour.rgb = YUVToRGB(vec3(luma, chroma));
    colour.rgb = clamp(LinearToSRGB(colour.rgb), vec3(0.0), vec3(1.0));

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = colour;
}
