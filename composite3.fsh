#include "lib/version.glsl"

varying vec2 texcoord;

#include "lib/uniforms.glsl"
#include "lib/common.glsl"

#ifdef VCR_TIMESTAMP
// Standard 7-segment truth table (a,b,c,d,e,f,g = 0..6). No bitwise ops
// here since GLSL 120 doesn't have them - just a plain lookup.
float SegOn(int digit, int seg)
{
    if (digit == 0) return (seg == 6) ? 0.0 : 1.0;
    if (digit == 1) return (seg == 1 || seg == 2) ? 1.0 : 0.0;
    if (digit == 2) return (seg == 0 || seg == 1 || seg == 6 || seg == 4 || seg == 3) ? 1.0 : 0.0;
    if (digit == 3) return (seg == 0 || seg == 1 || seg == 6 || seg == 2 || seg == 3) ? 1.0 : 0.0;
    if (digit == 4) return (seg == 5 || seg == 6 || seg == 1 || seg == 2) ? 1.0 : 0.0;
    if (digit == 5) return (seg == 0 || seg == 5 || seg == 6 || seg == 2 || seg == 3) ? 1.0 : 0.0;
    if (digit == 6) return (seg == 0 || seg == 5 || seg == 6 || seg == 4 || seg == 2 || seg == 3) ? 1.0 : 0.0;
    if (digit == 7) return (seg == 0 || seg == 1 || seg == 2) ? 1.0 : 0.0;
    if (digit == 8) return 1.0;
    if (digit == 9) return (seg == 0 || seg == 1 || seg == 2 || seg == 3 || seg == 5 || seg == 6) ? 1.0 : 0.0;
    return 0.0;
}

float SegRect(vec2 uv, vec2 center, vec2 halfsize)
{
    vec2 d = abs(uv - center) - halfsize;
    return step(max(d.x, d.y), 0.0);
}

// uv is local space within one digit's cell, 0..1 both axes.
float DrawDigit(vec2 uv, int digit)
{
    if (uv.x < -0.2 || uv.x > 1.2 || uv.y < -0.2 || uv.y > 1.2) return 0.0;

    float t = 0.13;
    float result = 0.0;

    result += SegOn(digit, 0) * SegRect(uv, vec2(0.5, 0.92), vec2(0.30, t * 0.5)); // a: top
    result += SegOn(digit, 6) * SegRect(uv, vec2(0.5, 0.5), vec2(0.28, t * 0.5));  // g: middle
    result += SegOn(digit, 3) * SegRect(uv, vec2(0.5, 0.08), vec2(0.30, t * 0.5)); // d: bottom

    result += SegOn(digit, 5) * SegRect(uv, vec2(0.14, 0.73), vec2(t * 0.5, 0.21)); // f: top-left
    result += SegOn(digit, 1) * SegRect(uv, vec2(0.86, 0.73), vec2(t * 0.5, 0.21)); // b: top-right
    result += SegOn(digit, 4) * SegRect(uv, vec2(0.14, 0.27), vec2(t * 0.5, 0.21)); // e: bottom-left
    result += SegOn(digit, 2) * SegRect(uv, vec2(0.86, 0.27), vec2(t * 0.5, 0.21)); // c: bottom-right

    return clamp(result, 0.0, 1.0);
}

// Blinking REC dot + a running MM:SS timecode, camcorder-OSD style. The
// clock counts up from when the shader loaded - there's no way for a
// shader to read a real wall-clock date/time, so this counts elapsed time
// instead of showing an actual date.
vec3 ApplyTimestamp(vec3 col, vec2 uv)
{
    vec2 rec_center = vec2(0.90, 0.94);
    float rec_dist = length((uv - rec_center) * vec2(1.0, viewHeight / viewWidth));
    float rec_dot = smoothstep(0.008, 0.006, rec_dist);
    float blink = step(0.5, fract(frameTimeCounter));
    col = mix(col, vec3(1.0, 0.15, 0.15), rec_dot * blink);

    float minutes = floor(mod(frameTimeCounter / 60.0, 60.0));
    float seconds = floor(mod(frameTimeCounter, 60.0));

    int d0 = int(floor(minutes / 10.0));
    int d1 = int(mod(minutes, 10.0));
    int d2 = int(floor(seconds / 10.0));
    int d3 = int(mod(seconds, 10.0));

    vec2 digit_size = vec2(0.018, 0.032);
    vec2 start = vec2(0.855, 0.885);
    float spacing = 0.022;

    float glow = 0.0;
    glow += DrawDigit((uv - (start + vec2(spacing * 0.0, 0.0))) / digit_size, d0);
    glow += DrawDigit((uv - (start + vec2(spacing * 1.0, 0.0))) / digit_size, d1);
    glow += DrawDigit((uv - (start + vec2(spacing * 2.3, 0.0))) / digit_size, d2);
    glow += DrawDigit((uv - (start + vec2(spacing * 3.3, 0.0))) / digit_size, d3);

    // Colon between minutes and seconds.
    vec2 colon_center = start + vec2(spacing * 1.95, 0.0) + digit_size * 0.5;
    float colon_dist1 = length(uv - (colon_center + vec2(0.0, digit_size.y * 0.18)));
    float colon_dist2 = length(uv - (colon_center - vec2(0.0, digit_size.y * 0.18)));
    glow += step(colon_dist1, 0.004) + step(colon_dist2, 0.004);

    col = mix(col, vec3(1.0, 0.95, 0.8), clamp(glow, 0.0, 1.0));
    return col;
}
#endif

void main()
{
    vec2 final_texcoord = texcoord;

    #ifdef SCREEN_CURVATURE
        // Extra barrel warp simulating a CRT tube's curved glass, on top
        // of (and separate from) LENS_DISTORTION's camera-lens warp.
        vec2 curved = texcoord * 2.0 - 1.0;
        curved *= 1.0 + dot(curved, curved) * 0.15 * SCREEN_CURVATURE_STRENGTH;
        curved = curved * 0.5 + 0.5;
        final_texcoord = curved;
    #endif

    vec4 colour = texture2D(colortex0, final_texcoord);
    vec4 prev_frame = colour;

    #ifdef INTERLACING
        prev_frame = texture2D(colortex4, final_texcoord);

        // Alternate which scanlines get updated this frame, holding the other
        // half back from the previous frame to fake interlaced fields.
        // Blending at partial strength (rather than a full swap) keeps the
        // effect from turning into heavy ghosting whenever the camera moves.
        float interlace_mask = fract(gl_FragCoord.y * 0.25) > 0.5 ? 1.0 : 0.0;
        interlace_mask = fract(frameTimeCounter * INTERLACE_FRAMERATE) > 0.5 ? 1.0 - interlace_mask : interlace_mask;

        colour = mix(colour, prev_frame, interlace_mask * INTERLACE_STRENGTH);
        prev_frame = colour;
    #endif

    #ifdef REWIND_STREAK
        // Stylised smeared horizontal motion trail, like tape spooling past
        // the head at speed. Shaders can't detect an actual rewind/FF
        // action, so this is a manually toggled look, not an automatic one.
        vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
        vec3 streak = vec3(0.0);
        for (int i = 1; i <= 6; i++)
        {
            vec2 off = vec2(float(i) * 3.0, 0.0) * texel * REWIND_STREAK_STRENGTH;
            streak += texture2D(colortex0, final_texcoord - off).rgb / float(i);
        }
        colour.rgb = mix(colour.rgb, streak, 0.5 * REWIND_STREAK_STRENGTH);
    #endif

    #ifdef VCR_TIMESTAMP
        // An on-screen display sits on top of the curved image, so it uses
        // plain texcoord rather than the (possibly curved) final_texcoord.
        colour.rgb = ApplyTimestamp(colour.rgb, texcoord);
    #endif

    #ifdef SCREEN_CURVATURE
        if (final_texcoord.x < 0.0 || final_texcoord.x > 1.0 || final_texcoord.y < 0.0 || final_texcoord.y > 1.0)
        {
            colour.rgb = vec3(0.0);
        }
        else
        {
            vec2 edge_dist = min(final_texcoord, 1.0 - final_texcoord);
            float corner_mask = smoothstep(-0.02, 0.015, min(edge_dist.x, edge_dist.y));
            colour.rgb *= corner_mask;
        }
    #endif

    /* DRAWBUFFERS:04 */
    gl_FragData[0] = colour;
    gl_FragData[1] = prev_frame;
}
