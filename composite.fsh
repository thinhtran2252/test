#include "lib/version.glsl"

varying vec2 texcoord;

#include "lib/uniforms.glsl"
#include "lib/common.glsl"

vec3 RGBToYUV(vec3 rgb)
{
    float y = 0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b;
    return vec3(y, 0.493 * (rgb.b - y), 0.877 * (rgb.r - y));
}

void main()
{
    vec2 final_texcoord = texcoord;

    #ifdef LENS_DISTORTION
        vec2 distorted = texcoord * 2.0 - 1.0;
        distorted *= 1.0 + dot(distorted, distorted) * 0.1;
        distorted = distorted * 0.85 * 0.5 + 0.5;
        final_texcoord = distorted;
    #endif

    #ifdef WOBBLE
        // Whole frame shakes side to side, like an unsteady tape/deck.
        float wobble_offset = (sin(frameTimeCounter * 3.7) * 0.6 + sin(frameTimeCounter * 7.3) * 0.4);
        final_texcoord.x += wobble_offset * WOBBLE_STRENGTH * 0.01;
    #endif

    #ifdef TRACKING_WAVE
        // Continuous wavy horizontal warp - tape just barely holding
        // tracking, as opposed to TRACKING_ERROR's occasional torn band.
        float wave_offset = sin(final_texcoord.y * 40.0 + frameTimeCounter * 2.0);
        final_texcoord.x += wave_offset * TRACKING_WAVE_STRENGTH * 0.01;
    #endif

    #ifdef PAUSE_JITTER
        // A shakier, less coherent jitter than WOBBLE, plus a little
        // vertical instability - meant to read as an unstable freeze-frame.
        // Manually toggled: shaders have no way to detect an actual pause.
        float jitter = sin(frameTimeCounter * 53.0) * 0.5
                      + sin(frameTimeCounter * 97.0) * 0.3
                      + sin(final_texcoord.y * 80.0) * 0.2;
        final_texcoord.x += jitter * PAUSE_JITTER_STRENGTH * 0.02;
        final_texcoord.y += sin(frameTimeCounter * 61.0) * PAUSE_JITTER_STRENGTH * 0.005;
    #endif

    #ifdef TRACKING_ERROR
        // A band drifts slowly down the screen; while a fragment is inside
        // it, tear the image sideways with a bit of fast jitter - a tape
        // struggling to hold tracking rather than a clean scroll.
        float band_y = fract(frameTimeCounter * 0.07);
        float dist_from_band = abs(final_texcoord.y - band_y);
        float in_band = smoothstep(0.025, 0.0, dist_from_band);
        float tear_jitter = sin(frameTimeCounter * 45.0 + final_texcoord.y * 40.0) * 0.5 + 0.5;
        final_texcoord.x += in_band * TRACKING_ERROR_STRENGTH * tear_jitter;
    #endif

    vec4 colour;
    #ifdef CHROMATIC_ABERRATION
        vec2 ca_offset = (texcoord - 0.5) * CHROMATIC_ABERRATION_STRENGTH * 0.01;
        colour.r = texture2D(colortex0, final_texcoord + ca_offset).r;
        colour.g = texture2D(colortex0, final_texcoord).g;
        colour.b = texture2D(colortex0, final_texcoord - ca_offset).b;
        colour.a = 1.0;
    #else
        colour = texture2D(colortex0, final_texcoord);
    #endif

    #ifdef COLOR_BLEED
        // Saturated colour (mostly red) trailing sideways into what comes
        // after it, the way it actually smears on analog tape.
        vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
        float bleed_r = 0.0;
        const int BLEED_TAPS = 4;
        for (int i = 1; i <= BLEED_TAPS; i++)
        {
            float w = 1.0 - float(i) / float(BLEED_TAPS);
            bleed_r += texture2D(colortex0, final_texcoord - vec2(float(i) * COLOR_BLEED_STRENGTH * 0.004, 0.0)).r * w;
        }
        bleed_r /= float(BLEED_TAPS);
        colour.r = mix(colour.r, max(colour.r, bleed_r), 0.6);
    #endif

    #ifdef HEAD_SWITCH_NOISE
        // Real VHS: the playback head physically switches between video
        // tracks right at the bottom of the frame, tearing that strip into
        // raw static. Fades out moving up from the very bottom edge.
        float switch_zone = smoothstep(0.05, 0.0, texcoord.y);
        if (switch_zone > 0.0)
        {
            vec2 switch_noise_coord = gl_FragCoord.xy / 32.0 + vec2(0.0, frameTimeCounter * 30.0);
            float switch_noise = texture2D(noisetex, switch_noise_coord).r;
            colour.rgb = mix(colour.rgb, vec3(switch_noise), switch_zone * HEAD_SWITCH_STRENGTH);
        }
    #endif

    #ifdef DROPOUT_LINES
        // A tape dropout losing signal on a scanline for an instant - a
        // rare, bright horizontal streak rather than a constant artifact.
        float dropout_step = floor(frameTimeCounter * 6.0);
        float dropout_seed = fract(sin(dropout_step * 45.164) * 22578.354);
        float has_dropout = step(1.0 - DROPOUT_STRENGTH * 0.15, dropout_seed);
        float dropout_y = fract(sin(dropout_step * 91.345) * 33333.777);
        float dist_from_dropout = abs(final_texcoord.y - dropout_y);
        float dropout_mask = has_dropout * smoothstep(0.006, 0.0, dist_from_dropout);
        colour.rgb = mix(colour.rgb, vec3(1.0), dropout_mask);
    #endif

    #ifdef FILM_DUST
        // Small black flecks that pop in and out of existence, plus thin
        // scratch lines - dirt and damage on old film/tape stock, not a
        // smoothly drifting texture.
        float dust_step = floor(frameTimeCounter * FILM_DUST_RATE);
        vec2 dust_coord = gl_FragCoord.xy / 3.0 + dust_step * 91.7;
        float dust_noise = texture2D(noisetex, dust_coord / 256.0).r;
        float dust = step(1.0 - FILM_DUST_DENSITY * 0.01, dust_noise);
        colour.rgb = mix(colour.rgb, vec3(0.0), dust * FILM_DUST_STRENGTH);

        // Occasional thin vertical scratch, position changes each dust step.
        float scratch_seed = fract(sin(dust_step * 12.9898) * 43758.5453);
        float scratch_x = fract(sin(dust_step * 78.233) * 12543.318);
        float has_scratch = step(0.85, scratch_seed);
        float dist_from_scratch = abs(final_texcoord.x - scratch_x);
        float scratch = has_scratch * smoothstep(0.0015, 0.0, dist_from_scratch);
        colour.rgb = mix(colour.rgb, vec3(0.0), scratch * FILM_DUST_STRENGTH * 0.6);
    #endif

    #ifdef STATIC_SNOW
        // Full-screen white noise blended in at adjustable strength - a
        // dead channel at full strength, a faint haze at low values.
        vec2 snow_coord = gl_FragCoord.xy + frameTimeCounter * 400.0;
        float snow = texture2D(noisetex, snow_coord / 256.0).r;
        colour.rgb = mix(colour.rgb, vec3(snow), STATIC_SNOW_STRENGTH);
    #endif

    #ifdef SIGNAL_LOSS
        // Brief, rare flashes of full static or inverted colour - a signal
        // cutting out for a frame or two.
        float loss_step = floor(frameTimeCounter * 8.0);
        float loss_seed = fract(sin(loss_step * 17.234) * 98765.432);
        if (loss_seed > 1.0 - 0.03 * SIGNAL_LOSS_STRENGTH)
        {
            float use_invert = fract(sin(loss_step * 3.71) * 5432.1);
            vec2 loss_snow_coord = gl_FragCoord.xy + frameTimeCounter * 500.0;
            vec3 loss_static = vec3(texture2D(noisetex, loss_snow_coord / 256.0).r);
            vec3 inverted = vec3(1.0) - colour.rgb;
            colour.rgb = use_invert > 0.5 ? loss_static : inverted;
        }
    #endif

    // Crush to a limited number of steps per channel, like a low bit-depth
    // tape signal. A static per-pixel dither breaks up banding on smooth
    // gradients (sky, lighting falloffs) that plain rounding leaves visible
    // - cheap (no texture fetch) and static so it doesn't add flicker.
    float dither = fract(sin(dot(gl_FragCoord.xy, vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
    colour.rgb = floor(colour.rgb * COLOUR_DEPTH + 0.5 + dither) / COLOUR_DEPTH;

    #ifdef FILM_GRAIN
        // A distinct textural grain layer, separate from the LUMA_NOISE/
        // CHROMA_NOISE signal-noise simulation below.
        vec2 grain_coord = gl_FragCoord.xy * 0.7 + frameTimeCounter * 60.0;
        float grain = texture2D(noisetex, grain_coord / 256.0).r - 0.5;
        colour.rgb += grain * FILM_GRAIN_STRENGTH;
    #endif

    // Move into YUV so luma and chroma can be treated separately downstream.
    colour.rgb = RGBToYUV(colour.rgb);

    vec2 noise_coord = gl_FragCoord.xy / 256.0;
    vec4 noise = texture2D(noisetex, noise_coord);
    noise = fract(noise + fract(frameTimeCounter * 5.0)) * 2.0 - 1.0;

    colour.r += noise.x * LUMA_NOISE * 0.5;
    colour.gb += noise.yz * CHROMA_NOISE * 0.5;

    #ifdef ASPECT_RATIO
        colour.rgb *= abs(texcoord.x * 2.0 - 1.0) < 0.75 ? 1.0 : 0.0;
    #endif

    // colortex0 is an ordinary 8-bit buffer, which can only store 0..1.
    // U/V are signed (roughly +-0.5 to +-0.9), so store them offset into
    // 0..1 here and undo the offset on the way back out in composite1.
    // Without this, every negative chroma value clips to 0 and the whole
    // image biases toward magenta/purple.
    colour.gb = colour.gb + 0.5;

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = colour;
}
