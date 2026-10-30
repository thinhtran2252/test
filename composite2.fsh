#include "lib/version.glsl"

varying vec2 texcoord;

#include "lib/uniforms.glsl"
#include "lib/common.glsl"

// 5-tap cross kernel (center + 4 neighbors). Cheaper than a full 3x3 (5
// taps instead of 9) - this pass runs by default on every pixel every
// frame, so it's worth trimming even though the 3x3 was already a
// reduction from the original 5x5.
const vec2 offsets[5] = vec2[5](
    vec2(0, 0), vec2(1, 0), vec2(-1, 0), vec2(0, 1), vec2(0, -1)
);

const float weights[5] = float[5](
    4.0, 1.0, 1.0, 1.0, 1.0
);

vec3 ApplyColourGrade(vec3 col)
{
    #if COLOUR_GRADE == 1
        // Backrooms: sickly yellow fluorescent tint, slightly desaturated.
        vec3 graded = col * vec3(1.08, 1.02, 0.78) + vec3(0.02, 0.015, -0.01);
        float luma = dot(graded, vec3(0.299, 0.587, 0.114));
        return mix(vec3(luma), graded, 0.85);
    #elif COLOUR_GRADE == 2
        // Poolrooms: bright, clean, light-blue tile-and-water tint.
        vec3 graded = col * vec3(0.95, 1.02, 1.08) + vec3(0.0, 0.01, 0.02);
        float luma = dot(graded, vec3(0.299, 0.587, 0.114));
        return mix(graded, vec3(luma), 0.05);
    #elif COLOUR_GRADE == 3
        // Liminal Night: cool the shadows toward blue without brightening
        // the scene, so the dark/eerie mood stays intact.
        float luma = dot(col, vec3(0.299, 0.587, 0.114));
        vec3 shadow_tint = vec3(0.85, 0.92, 1.1);
        return col * mix(shadow_tint, vec3(1.0), luma) * 0.97;
    #elif COLOUR_GRADE == 4
        // Parking Garage: sodium-vapor orange tint, darker shadows push
        // further orange than the highlights do.
        vec3 graded = col * vec3(1.15, 0.95, 0.65);
        float luma = dot(graded, vec3(0.299, 0.587, 0.114));
        vec3 shadow_tint = vec3(1.1, 0.85, 0.55);
        return graded * mix(shadow_tint, vec3(1.0), luma) * 0.85;
    #elif COLOUR_GRADE == 5
        // Dead Channel: cold, heavily desaturated, gritty static-TV look.
        float luma = dot(col, vec3(0.299, 0.587, 0.114));
        vec3 desat = mix(col, vec3(luma), 0.6);
        return desat * vec3(0.92, 0.95, 1.02);
    #elif COLOUR_GRADE == 6
        // Lost: heavy fog washes everything toward a flat, low-contrast
        // grey - low visibility, nothing reads as vivid anymore.
        float luma = dot(col, vec3(0.299, 0.587, 0.114));
        vec3 desat = mix(col, vec3(luma), 0.55);
        vec3 fog_lift = mix(desat, vec3(0.55, 0.57, 0.6), 0.15);
        return fog_lift * vec3(0.95, 0.97, 1.0);
    #elif COLOUR_GRADE == 7
        // After Hours: dim, quiet, cool-neutral - the lights are still on
        // but nobody's around.
        vec3 graded = col * vec3(0.93, 0.95, 1.0);
        float luma = dot(graded, vec3(0.299, 0.587, 0.114));
        graded = mix(vec3(luma), graded, 0.9);
        return graded * 0.85;
    #elif COLOUR_GRADE == 8
        // Forgotten: dusty, faded, warm desaturation - like a photo left
        // in the sun, everything a bit sepia and a bit flat.
        float luma = dot(col, vec3(0.299, 0.587, 0.114));
        vec3 desat = mix(col, vec3(luma), 0.45);
        vec3 faded = mix(desat, vec3(0.62, 0.56, 0.46), 0.15);
        return faded * vec3(1.03, 0.98, 0.9);
    #elif COLOUR_GRADE == 9
        // Body Camera: cool-neutral, punchier contrast, mild desaturation -
        // the flat, slightly clinical look of digital security/body-worn
        // camera footage rather than analog tape.
        float luma = dot(col, vec3(0.299, 0.587, 0.114));
        vec3 desat = mix(col, vec3(luma), 0.25);
        vec3 graded = desat * vec3(0.97, 1.0, 1.02);
        graded = (graded - 0.5) * 1.15 + 0.5;
        return graded;
    #else
        return col;
    #endif
}

float Vignette(vec2 uv)
{
    if (VIGNETTE_STRENGTH <= 0.0) return 1.0;

    vec2 centered = uv * 2.0 - 1.0;
    float dist = length(centered * vec2(1.0, viewHeight / viewWidth));
    return 1.0 - VIGNETTE_STRENGTH * smoothstep(0.4, 1.1, dist);
}

#ifdef CCD_SMEAR
// Real CCD camera sensors bleed charge vertically down their shift
// registers when a pixel is badly overexposed - streetlights, headlights,
// any small bright source turns into a coloured vertical streak running
// through it. This approximates that with a handful of taps stepping away
// from the pixel along the column, picking up any overexposed source and
// fading it out with distance. Compiled out entirely when the option is
// off, so it costs nothing unless enabled.
vec3 CCDSmear(vec2 uv)
{
    vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
    float step_size = CCD_SMEAR_LENGTH * viewHeight * 0.01 / float(CCD_SMEAR_TAPS);
    vec3 smear = vec3(0.0);

    for (int i = 1; i <= CCD_SMEAR_TAPS; i++)
    {
        float falloff = 1.0 - float(i) / float(CCD_SMEAR_TAPS);
        falloff *= falloff;
        vec2 offset = vec2(0.0, float(i) * step_size) * texel;

        // Smear mostly downward from the source (how a real CCD's shift
        // register reads out), with a much weaker upward ghost too.
        vec3 below = texture2D(colortex0, uv - offset).rgb;
        float below_bright = max(below.r, max(below.g, below.b));
        smear += below * smoothstep(0.75, 1.0, below_bright) * falloff;

        vec3 above = texture2D(colortex0, uv + offset).rgb;
        float above_bright = max(above.r, max(above.g, above.b));
        smear += above * smoothstep(0.75, 1.0, above_bright) * falloff * 0.3;
    }

    return smear / float(CCD_SMEAR_TAPS);
}
#endif

#ifdef BLOOM
// Bright areas glow outward in every direction, unlike CCD_SMEAR's
// vertical-only streak. Compiled out entirely when off.
vec3 Bloom(vec2 uv)
{
    vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
    vec3 glow = vec3(0.0);

    for (int i = 0; i < 8; i++)
    {
        float angle = float(i) / 8.0 * 6.28318;
        vec2 offset = vec2(cos(angle), sin(angle)) * 4.0 * texel;
        vec3 s = texture2D(colortex0, uv + offset).rgb;
        float bright = max(s.r, max(s.g, s.b));
        float over = smoothstep(BLOOM_THRESHOLD, 1.0, bright);
        glow += s * over;
    }

    return glow / 8.0;
}
#endif

void main()
{
    vec4 colour = texture2D(colortex0, texcoord);

    // Positive sharpens toward the source, negative pushes toward the blur
    // itself - real analog tape softness rather than just "not sharpened".
    if (SHARPNESS != 0.0)
    {
        vec3 blurred = vec3(0.0);
        vec2 px = 1.0 / vec2(viewWidth, viewHeight);

        for (int i = 0; i < 5; i++)
        {
            blurred += texture2D(colortex0, texcoord + offsets[i] * px).rgb * weights[i];
        }

        // weights sum to 8 -> 1/8 = 0.125
        colour.rgb = mix(colour.rgb, blurred * 0.125, -1.0 * SHARPNESS);
    }

    colour.rgb = ApplyColourGrade(colour.rgb);

    if (DESATURATION > 0.0)
    {
        float luma = dot(colour.rgb, vec3(0.299, 0.587, 0.114));
        colour.rgb = mix(colour.rgb, vec3(luma), DESATURATION);
    }

    #ifdef CCD_SMEAR
        colour.rgb += CCDSmear(texcoord) * vec3(1.3, 0.85, 1.3) * CCD_SMEAR_STRENGTH;
    #endif

    #ifdef BLOOM
        colour.rgb += Bloom(texcoord) * BLOOM_STRENGTH;
    #endif

    #ifdef SCAN_LINES
        // Alternating dark/light rows at native pixel resolution.
        float scan = sin(gl_FragCoord.y * 3.14159) * 0.5 + 0.5;
        colour.rgb *= mix(1.0 - SCAN_LINE_STRENGTH, 1.0, scan);
    #endif

    colour.rgb *= Vignette(texcoord);

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = colour;
}
